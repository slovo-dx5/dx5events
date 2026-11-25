package com.cioafrica.dx5veevents

import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.ContactsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dx5ve/contacts")
            .setMethodCallHandler { call, result ->
                if (call.method != "insertViaContactsApp") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    result.success(openInsertContact(call.arguments as Map<*, *>))
                } catch (e: Exception) {
                    result.error("insert_failed", e.message, null)
                }
            }
    }

    // Hands a scanned delegate to the phone's Contacts app, pre-filled, for the
    // user to confirm. flutter_contacts' direct insert crashes the app (or never
    // returns) on Android 16+, and this needs no contacts permission at all.
    private fun openInsertContact(args: Map<*, *>): Boolean {
        fun s(key: String) = (args[key] as? String)?.trim().orEmpty()
        val name = listOf(s("firstName"), s("lastName")).filter { it.isNotEmpty() }.joinToString(" ")

        val intent = Intent(ContactsContract.Intents.Insert.ACTION).apply {
            type = ContactsContract.RawContacts.CONTENT_TYPE
            if (name.isNotEmpty()) putExtra(ContactsContract.Intents.Insert.NAME, name)
            if (s("phone").isNotEmpty()) putExtra(ContactsContract.Intents.Insert.PHONE, s("phone"))
            if (s("email").isNotEmpty()) putExtra(ContactsContract.Intents.Insert.EMAIL, s("email"))
            if (s("company").isNotEmpty()) putExtra(ContactsContract.Intents.Insert.COMPANY, s("company"))
            if (s("role").isNotEmpty()) putExtra(ContactsContract.Intents.Insert.JOB_TITLE, s("role"))
            // Samsung's Contacts app otherwise stays open on the new contact.
            putExtra("finishActivityOnSaveCompleted", true)
        }
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }
}
