package com.tobykurien.webmediashare.fragment

import android.app.ProgressDialog
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.support.v4.app.DialogFragment
import android.support.v7.app.AlertDialog
import android.util.Log
import android.webkit.CookieManager
import com.tobykurien.webmediashare.R
import com.tobykurien.webmediashare.activity.BaseWebAppActivity
import com.tobykurien.webmediashare.activity.WebAppActivity
import com.tobykurien.webmediashare.data.Webapp
import java.io.InputStream
import java.net.URL
import java.net.URLConnection
import org.xtendroid.annotations.AndroidDialogFragment

import static org.xtendroid.utils.AsyncBuilder.*

import static extension com.tobykurien.webmediashare.utils.Dependencies.*
import static extension org.xtendroid.utils.AlertUtils.*
import android.content.Context
import android.webkit.CookieSyncManager
import android.os.Build
import com.tobykurien.webmediashare.webviewclient.WebClient

/**
 * Dialog to open a URL.
 */
@AndroidDialogFragment(R.layout.dlg_open_url) class DlgOpenUrl extends DialogFragment {

	/**
	 * Create a dialog using the AlertDialog Builder, but our custom layout
	 */
	override onCreateDialog(Bundle instance) {
		new AlertDialog.Builder(activity)
			.setTitle(R.string.open_site)
			.setView(contentView) // contentView is the layout specified in the annotation
			.setPositiveButton(android.R.string.ok, null) // to avoid it closing dialog
			.setNegativeButton(android.R.string.cancel, null)
			.setNeutralButton(R.string.btn_recommended_sites, [
				var link = Uri.parse("https://github.com/tobykurien/WebApps/wiki/Recommended-Webapps")
				WebClient.handleExternalLink(activity, link, false);
				dismiss()
			  ])
			.create()
	}

	override onStart() {
		super.onStart()

		val button = (dialog as AlertDialog).getButton(AlertDialog.BUTTON_POSITIVE)
		button.setOnClickListener [
			if (onOpenUrlClick()) {
				dialog.dismiss
			}
		]
	}

	def boolean onOpenUrlClick() {
		var url = txtOpenUrl.text.toString;
		try {
			openUrl(activity, url, chkNewSandbox.checked)
		} catch (Exception e) {
			txtOpenUrl.setError(getString(R.string.err_invalid_url), null)
			return false
		}

		return true
	}

	def static openUrl(Context activity, String url, boolean newSandbox) {
		var Uri uri = null
		try {
			if (url.trim().length == 0) throw new Exception();

		    if (!url.contains("://")) {
				uri = Uri.parse("http://" + url)
			} else {
                uri = Uri.parse(url)
            }
		} catch (Exception e) {
			Log.e("dlgOpenUrl", "Error opening url", e)
			return false
		}

		// When opening a new URL, let's follow all redirects to get to the final destination
		val originalUri = uri
		val pd = new ProgressDialog(activity)
		pd.setMessage(activity.getString(R.string.progress_opening_site))

		async(pd) [
			var URLConnection con = new URL(originalUri.toString()).openConnection()
			if (activity.settings.userAgent != null &&
				activity.settings.userAgent.trim().length > 0) {
				// User-agent may affect site redirects
				con.setRequestProperty("User-Agent", activity.settings.userAgent)
			}
			con.connect()
			var InputStream is = con.getInputStream()
			var finalUrl = con.getURL()
			is.close()
			return finalUrl.toString()
		].then [ result |
			if (!pd.isShowing) return; // user cancelled

			var Uri uriFinal = null
			if (!result.equals(originalUri.toString())) {
				uriFinal = Uri.parse(result)
			} else {
				uriFinal = originalUri
			}

			if (!uriFinal.getScheme().equals("https")) {
				// force it to https
				var builder = uriFinal.buildUpon()
				builder.scheme("https")
				uriFinal = builder.build()
			}

			if (newSandbox) {
				// open in new sandbox
				// delete all previous cookies
				CookieManager.instance.removeAllCookie()
				var i = new Intent(activity, WebAppActivity)
				i.action = Intent.ACTION_VIEW
				i.data = uriFinal
				activity.startActivity(i)

			} else {
				WebClient.handleExternalLink(activity, uriFinal, false)
			}
		].onError[ Exception error |
			Log.e("dlgOpenUrl", "Error", error)
			try {
				activity.toast(error.message)
			} catch (Exception e) {
				// ignore, dialog must be dismissed
			}
		].start()

		return false
	}
}
