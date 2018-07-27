package com.tobykurien.webmediashare.fragment

import android.app.ProgressDialog
import android.net.http.SslCertificate
import android.os.Bundle
import android.support.v4.app.DialogFragment
import android.support.v7.app.AlertDialog
import android.util.Log
import com.tobykurien.webmediashare.R
import com.tobykurien.webmediashare.data.Webapp
import com.tobykurien.webmediashare.db.DbService
import java.util.Set
import org.eclipse.xtext.xbase.lib.Functions.Function1
import org.xtendroid.annotations.AndroidDialogFragment
import org.xtendroid.utils.AsyncBuilder

import static extension com.tobykurien.webmediashare.utils.Dependencies.*
import static extension org.xtendroid.utils.AlertUtils.*

/**
 * Dialog to save a Webapp.
 */
@AndroidDialogFragment(R.layout.dlg_save) class DlgSaveWebapp extends DialogFragment {
   long webappId
   var String title
   var String url
   var Set<String> unblock
   var Function1<Webapp, Void> onSave
   var SslCertificate certificate
   
   public new(long webappId, String title, String url, SslCertificate certificate, Set<String> unblock) {
      this.webappId = webappId
      this.title = title
      this.url = url
      this.unblock = unblock
      this.certificate = certificate
   }

   /**
    * Create a dialog using the AlertDialog Builder, but our custom layout
    */
   override onCreateDialog(Bundle instance) {
      new AlertDialog.Builder(activity)
         .setTitle(R.string.title_save_webapp)
         .setView(contentView)  // contentView is the layout specified in the annotation
         .setPositiveButton(android.R.string.ok, null) // to avoid it closing dialog
         .setNegativeButton(android.R.string.cancel, null)
         .create()
   }
   
   override onStart() {
      super.onStart()
      
      val button = (dialog as AlertDialog).getButton(AlertDialog.BUTTON_POSITIVE)
      button.setOnClickListener [
         onSaveClick()
      ]
      
      name.text = title
   }
 
   def void onSaveClick() {
      val pd = new ProgressDialog(activity)
      pd.message = getString(R.string.msg_saving_webapp)
      
      AsyncBuilder.async(pd) [builder, params|
         val values = #{
            "name" -> name.text.toString,
            "url" -> this.url
         }

         if (webappId >= 0) {
            activity.db.update(DbService.TABLE_WEBAPPS, values,
                  String.valueOf(webappId));
         } else {
            webappId = activity.db.insert(DbService.TABLE_WEBAPPS, values);
         }
   
         // NOTE: saving of unblock list moved to the 3rdparty dialog
   
         return activity.db.findById(DbService.TABLE_WEBAPPS, webappId, Webapp);
      ].then[ result |
         dismiss
         if (result === null) throw new Exception("Webapp did not save to database")
         if (onSave != null) {
            onSave.apply(result)
         }
      ].onError[Exception err|
         Log.e("dlg_save", "error saving webapp", err)
         activity.toast(err.class.name + ": " + err.message)
      ].start()
  }  
  
  def void setOnSaveListener(Function1<Webapp, Void> listener) {
     onSave = listener
  }
}