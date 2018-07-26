package com.tobykurien.webmediashare.utils

import android.net.http.SslCertificate
import com.tobykurien.webmediashare.data.Webapp
import com.tobykurien.webmediashare.db.DbService
import java.io.UnsupportedEncodingException
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException

class CertificateUtils {
    def static String SHA1(String text) throws NoSuchAlgorithmException, UnsupportedEncodingException {
        var md = MessageDigest.getInstance("SHA-1");
        var textBytes = text.getBytes("iso-8859-1");
        md.update(textBytes, 0, textBytes.length);
        var sha1hash = md.digest();
        return sha1hash.map[ Integer.toHexString(it) ].join();
    }	
	
	// Create a hash of the certificate for comparison
	def static String certificateHash(SslCertificate certificate) {
		SHA1(certificate.issuedBy.DName + 
				certificate.issuedTo.DName)
	}
	
	// Create a hash of the webapp's saved certificate details for comparison
	def static String certificateHash(Webapp webapp) {
		SHA1(webapp.certIssuedBy + 
				webapp.certIssuedTo)
	}
		
	def static int compare(SslCertificate cert1, SslCertificate cert2) {
		cert1.certificateHash.compareTo(cert2.certificateHash)
	}

	def static int compare(Webapp webapp, SslCertificate cert2) {
		webapp.certificateHash.compareTo(cert2.certificateHash)
	}

	// Save the certificate details to the webapp	
	def static void updateCertificate(Webapp webapp, SslCertificate certificate, DbService db) {
		if (certificate == null || certificate.issuedBy == null ||
			certificate.issuedTo == null) return;
		
		db.update(DbService.TABLE_WEBAPPS, #{
			'certIssuedBy' -> certificate.issuedBy.DName,
			'certIssuedTo' -> certificate.issuedTo.DName,
			'certValidFrom' -> certificate.validNotBefore,
			'certValidTo' -> certificate.validNotAfter
		}, webapp.id)				
	}
}