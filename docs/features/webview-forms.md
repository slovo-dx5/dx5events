# WebView forms (feedback and others)

The app can show a form we host ourselves in a WebView, instead of a native screen. Each submission is saved to Directus together with the attendee who sent it.

## Directus

| Collection | Field | Purpose |
|---|---|---|
| `app_webview_links` (singleton) | `event_feedback_form` | URL of the feedback form. If it's empty or not an http(s) URL, the app uses its native feedback screen. |
| `app_webview_links_data` | `link` | The form URL the submission came from. |
| | `user_details` (JSON) | Attendee details (see below) plus `submitted_at`. |
| | `data` (JSON) | Whatever the page submits. |

The app's API token needs **read** on `app_webview_links` and **create** on `app_webview_links_data`.

The app fetches the links at startup and caches them. A change in Directus shows up on the next app launch.

## Code

- `lib/services/webview_links/webview_links_service.dart` fetches and caches the links. It also has `buildUserDetails()`.
- `lib/screens/webview_form_screen.dart` is the generic WebView form screen and its bridge.
- `lib/screens/feedback_entry.dart` opens the hosted form, or falls back to the native `FeedbackPage`.
- `DioPostService.sendWebviewFormData()` does the POST to `app_webview_links_data`.

## Bridge contract for form authors

The app → page direction, after every page load:

```js
window.isFlutterApp = true;
window.DX5_USER = {
  attendee_id, first_name, last_name, name, email, phone,
  company, role, event_id, event_title, platform
};
window.dispatchEvent(new CustomEvent('dx5:ready', { detail: window.DX5_USER }));
```

The page → app direction, through the `DX5Form` JavaScript channel:

```js
DX5Form.postMessage(JSON.stringify({ type: 'submit', data: { /* any fields */ } }));
DX5Form.postMessage(JSON.stringify({ type: 'close' }));
```

After a submit, the app calls `window.dx5OnSubmitResult(ok)`:

- **`true`:** the submission was saved and the app closes the screen.
- **`false`:** saving failed, for example because the attendee is offline. The page stays open with its answers, so the user can submit again. Re-enable your submit button here.

Notes for form authors:

- The page doesn't need to send the user details. The app adds them.
- Links to other hosts open in the external browser.
- If the page is opened outside the app, `window.DX5Form` is undefined. Show a "please open this in the app" message.

## CIO Africa surveys (surveys.cioafrica.co): no bridge needed

The survey app saves to Supabase through `rpc("submit_survey_response", ...)` and doesn't call `DX5Form`. To capture it anyway, `WebViewFormScreen` injects a script that wraps `window.fetch`. When a POST to `/rest/v1/rpc/submit_survey_response` succeeds, the script passes the request body to the app.

The app saves it to `app_webview_links_data` with these fields in `data`:

```json
{ "source": "cioafrica_survey", "survey_slug", "response", "time_seconds",
  "completion_status", "respondent_email" }
```

- The survey still saves to Supabase as before.
- If the Directus save fails, the app retries it up to 3 times.
- The screen closes 2 seconds after the survey's thank-you appears.
- If the survey app changes the name of that RPC, update `_captureScript`.

## Minimal example

```html
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Feedback</title>
</head>
<body>
  <p id="hello">Loading…</p>
  <form id="f">
    <label>How was the event? <input name="rating" type="number" min="1" max="5" required></label>
    <label>Comments <textarea name="comments"></textarea></label>
    <button id="send">Submit</button>
  </form>
  <script>
    const hello = document.getElementById('hello');
    const send = document.getElementById('send');
    if (!window.DX5Form) hello.textContent = 'Please open this form in the DX5VE Events app.';
    window.addEventListener('dx5:ready', e => { hello.textContent = 'Hi ' + (e.detail.first_name || 'there'); });
    window.dx5OnSubmitResult = ok => { if (!ok) send.disabled = false; };
    document.getElementById('f').addEventListener('submit', ev => {
      ev.preventDefault();
      if (!window.DX5Form) return;
      send.disabled = true;
      const data = Object.fromEntries(new FormData(ev.target));
      DX5Form.postMessage(JSON.stringify({ type: 'submit', data }));
    });
  </script>
</body>
</html>
```
