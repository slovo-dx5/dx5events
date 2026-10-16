import { Directus } from '@directus/sdk';
import { SERVER_URL, SERVER_AUTH_TOKEN } from '$env/static/private';
import { getTransactionStatus } from '$lib/server/pesapalGatewayClient.js';
import { orderPayloadDataRepository, tempStoreRepository } from '$lib/server/cache/cache.js';
import { normalizePaymentStatus, processTransaction } from '$lib/server/paymentProcessing.js';

const directus = new Directus(`${SERVER_URL}`, { auth: { staticToken: `${SERVER_AUTH_TOKEN}` } });

export const load = async ({ url, locals }) => {
	const orderTrackingId = url.searchParams.get('OrderTrackingId');
	const sessionCookieId = locals.sessionCookieId;

	// Get registration data
	let registrationData = await orderPayloadDataRepository.fetch(sessionCookieId);

	let payment;

	if (!registrationData) {
		console.log('No registration data found for session cookie:', sessionCookieId);
		return {
			orderDetails: {
				error: 'Registration data not found',
				paymentStatus: 'Unknown'
			}
		};
	}

	if (orderTrackingId) {
		try {
			const updatedData = {
				...registrationData,
				orderTrackingId: orderTrackingId
			};

			await orderPayloadDataRepository.save(sessionCookieId, updatedData);

			console.log(
				`Updated cache with orderTrackingId ${orderTrackingId} for session ${sessionCookieId}`
			);
		} catch (error) {
			console.error('Error updating orderTrackingId in cache:', error);
		}
	} else {
		console.log('No OrderTrackingId found in URL query params.');
	}

	// Process transaction based on payment method
	let transactionStatus = null;

	// Check the payment method from registration data
	const paymentMethod = registrationData.paymentMethod?.toLowerCase();

	// Handle Pesapal transactions
	if (registrationData.requiresPayment && paymentMethod !== 'mpesa') {
		try {
			console.log('Getting Pesapal transaction status for order ID:', orderTrackingId);
			transactionStatus = await getTransactionStatus(orderTrackingId);
			console.log('Pesapal transaction status received:', transactionStatus);

			if (transactionStatus) {
				// Handle Pesapal transaction
				await processTransaction(transactionStatus, registrationData, orderTrackingId, 'pesapal');
			}
		} catch (error) {
			console.error('Error processing Pesapal transaction:', error);
		}
	}

	// Handle M-Pesa transactions
	else if (registrationData.requiresPayment && paymentMethod === 'mpesa') {
		try {
			console.log('Getting M-Pesa transaction status for order ID:', orderTrackingId);

			// For M-Pesa, we need to get the payment record from Directus
			const paymentRecord = await directus.items('payments').readByQuery({
				filter: {
					order_tracking_id: { _eq: orderTrackingId }
				}
			});

			if (paymentRecord?.data?.length > 0) {
				payment = paymentRecord.data[0];

				// Create transaction status object to match Pesapal format
				transactionStatus = {
					payment_method: payment.payment_method,
					confirmation_code: payment.confirmation_code,
					payment_status_description: payment.payment_status_description,
					description: payment.payment_status_description,
					payment_account: payment.payment_account,
					merchant_reference: payment.merchant_reference || payment.order_tracking_id,
					created_date: payment.payment_datetime,
					amount: payment.amount,
					currency: payment.currency
				};

				registrationData = {
					...registrationData,
					receiptUrl: payment.receipt_url || null
				};

				// Process M-Pesa transaction
				await processTransaction(transactionStatus, registrationData, orderTrackingId, 'mpesa');
			} else {
				console.log('No M-Pesa payment record found for order ID:', orderTrackingId);
			}
		} catch (error) {
			console.error('Error processing M-Pesa transaction:', error);
		}
	}

	// Create sanitized version of registration data
	const sanitizedRegistrationData = {
		eventId: registrationData.eventId,
		eventTitle: registrationData.eventTitle,
		eventTitleSlug: registrationData.eventTitleSlug,
		eventBanner: registrationData.eventBanner,
		eventDateFrom: registrationData.eventDateFrom,
		eventDateTo: registrationData.eventDateTo,
		eventVenue: registrationData.eventVenue,
		eventType: registrationData.eventType,

		ticketId: registrationData.ticketId,
		ticketName: registrationData.ticketName,
		ticketCount: registrationData.ticketCount || 1,
		ticketCurrency: registrationData.ticketCurrency,
		ticketPrice: registrationData.ticketPrice,
		ticketAccPriceWithVAT: registrationData.ticketAccPriceWithVAT,

		ticketHasDiscountCode: registrationData.ticketHasDiscountCode,
		ticketDiscountCodeIsValid: registrationData.ticketDiscountCodeIsValid,
		ticketDiscountCode: registrationData.ticketDiscountCode || '',
		ticketDiscountRate: registrationData.ticketDiscountRate || 0,

		referralCode: registrationData.referralCode || '',
		referrer: registrationData.referrer || '',
		referrerEmail: registrationData.referrerEmail || '',

		registrationId: registrationData.registrationId || orderTrackingId,
		isGroupRegistration: registrationData.isGroupRegistration || false
	};

	// Create sanitized version of transaction data if available
	const sanitizedTransactionDetails = transactionStatus
		? {
				orderTrackingId: orderTrackingId || '',
				payment_method: transactionStatus.payment_method,
				confirmation_code: transactionStatus.confirmation_code,
				payment_status_description: transactionStatus.payment_status_description,
				description: transactionStatus.description,
				payment_account: transactionStatus.payment_account,
				merchant_reference: transactionStatus.merchant_reference,
				created_date: transactionStatus.created_date,
				amount: transactionStatus.amount,
				currency: transactionStatus.currency
		  }
		: null;

	// Return safe, serializable data with normalized payment status
	return {
		orderDetails: {
			...sanitizedRegistrationData,
			paymentStatus:
				normalizePaymentStatus(sanitizedTransactionDetails?.payment_status_description) ||
				'Pending',
			paymentMethod: sanitizedTransactionDetails?.payment_method || null,
			confirmationCode: sanitizedTransactionDetails?.confirmation_code || null,

			receiptUrl: payment?.receipt_url || null,
			// Include customer details if available, but sanitize first
			customerDetails: registrationData.customerDetails
				? {
						firstName: registrationData.customerDetails.firstName,
						lastName: registrationData.customerDetails.lastName,
						email: registrationData.customerDetails.email,
						phone: registrationData.customerDetails.phone,
						company: registrationData.customerDetails.company,
						role: registrationData.customerDetails.role,
						industry: registrationData.customerDetails.industry,
						country: registrationData.customerDetails.country
				  }
				: null,

			// Include sanitized participants data if it's a group registration
			allParticipants: registrationData.allParticipants
				? registrationData.allParticipants.map((p) => ({
						firstName: p.firstName,
						lastName: p.lastName,
						email: p.email,
						phone: p.phone,
						company: p.company,
						role: p.role,
						industry: p.industry,
						country: p.country
				  }))
				: [],

			// Include sanitized transaction data
			transactionDetails: sanitizedTransactionDetails
		}
	};
};
