// @ts-check
import { json } from '@sveltejs/kit';
import { processTransaction } from '$lib/server/paymentProcessing.js';
import { orderPayloadDataRepository } from '$lib/server/cache/cache.js';
import { Directus } from '@directus/sdk';
import { SERVER_URL, SERVER_AUTH_TOKEN, PESAPAL_WEBHOOK_SECRET } from '$env/static/private';

const directus = new Directus(`${SERVER_URL}`, { auth: { staticToken: `${SERVER_AUTH_TOKEN}` } });

export async function POST({ request }) {
	const providedSecret = request.headers.get('x-webhook-secret');
	if (!providedSecret || providedSecret !== PESAPAL_WEBHOOK_SECRET) {
		return json({ error: 'Unauthorized' }, { status: 401 });
	}

	let body;
	try {
		body = await request.json();
	} catch (error) {
		console.error('Error parsing payment webhook body:', error);
		return json({ received: true });
	}

	const orderTrackingId = body.order_tracking_id;

	if (!orderTrackingId) {
		return json({ error: 'order_tracking_id is required' }, { status: 400 });
	}

	try {
		// The payment record already has the session/registration data
		// attached (created during checkout), so look it up by tracking id
		// rather than by session cookie (the webhook has no browser session).
		const paymentResponse = await directus.items('payments').readByQuery({
			filter: {
				_or: [
					{ order_tracking_id: { _eq: orderTrackingId } },
					{ order_tracking_id: { _eq: body.merchant_reference } }
				]
			}
		});

		const paymentRecord = paymentResponse?.data?.[0];
		if (!paymentRecord) {
			console.log('Webhook received for unknown order_tracking_id:', orderTrackingId);
			return json({ received: true });
		}

		const sessionCookieId = paymentRecord.sessionCookieId;
		const registrationData = sessionCookieId
			? await orderPayloadDataRepository.fetch(sessionCookieId)
			: null;

		if (!registrationData) {
			console.log('No cached registration data for webhook order_tracking_id:', orderTrackingId);
			return json({ received: true });
		}

		// The order id submitted to the gateway is derived the same way at
		// checkout time (see events/[slug]/checkout/+page.server.js), so use
		// the same fallback here rather than registrationId alone.
		const cachedOrderId = registrationData.registrationId || registrationData.orderTrackingId;

		if (cachedOrderId !== body.merchant_reference) {
			console.log(
				'Cached registration data does not match this webhook order (session may have moved on to a new order), skipping:',
				{ expected: body.merchant_reference, cached: cachedOrderId }
			);
			return json({ received: true });
		}

		await processTransaction(body, registrationData, orderTrackingId, 'pesapal');
	} catch (error) {
		console.error('Error processing payment webhook:', error);
	}

	return json({ received: true });
}
