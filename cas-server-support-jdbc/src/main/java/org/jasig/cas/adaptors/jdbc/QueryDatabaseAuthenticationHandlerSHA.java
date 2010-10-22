/*
 * Copyright 2007 The JA-SIG Collaborative. All rights reserved. See license
 * distributed with this file and available online at
 * http://www.ja-sig.org/products/cas/overview/license/
 */
package org.jasig.cas.adaptors.jdbc;

import org.jasig.cas.authentication.handler.AuthenticationException;
import org.jasig.cas.authentication.principal.UsernamePasswordCredentials;
import org.springframework.dao.IncorrectResultSizeDataAccessException;

import javax.validation.constraints.NotNull;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.io.UnsupportedEncodingException;

/**
 * Class that if provided a query that returns a password (parameter of query
 * must be username) will compare that password to a translated version of the
 * password provided by the user. If they match, then authentication succeeds.
 * Default password translator is plaintext translator.
 * 
 * @author Scott Battaglia
 * @author Dmitriy Kopylenko
 * @version $Revision: 19533 $ $Date: 2009-12-14 23:33:36 -0500 (Mon, 14 Dec 2009) $
 * @since 3.0
 */
public final class QueryDatabaseAuthenticationHandlerSHA extends
    AbstractJdbcUsernamePasswordAuthenticationHandler {

    @NotNull
    private String sql;

    protected final boolean authenticateUsernamePasswordInternal(final UsernamePasswordCredentials credentials) throws AuthenticationException {
        final String username = getPrincipalNameTransformer().transform(credentials.getUsername());
        final String password = credentials.getPassword();
        //final String encryptedPassword = this.getPasswordEncoder().encode(
        //    password);
        final String encryptedPassword = hash(password);
        
        try {
            final String dbPassword = getJdbcTemplate().queryForObject(
                this.sql, String.class, username);
            return dbPassword.equals(encryptedPassword);
        } catch (final IncorrectResultSizeDataAccessException e) {
            // this means the username was not found.
            return false;
        }
    }
    
    public static String hash(String plaintext) {
    	MessageDigest md = null;
    	try {
    		md = MessageDigest.getInstance("SHA");
    	} catch(NoSuchAlgorithmException e) {
    		return "";
    	}
    	
    	try {
    		md.update(plaintext.getBytes("UTF-8"));
    	} catch(UnsupportedEncodingException e) {
    		return "";
    	}
    	
    	byte raw[] = md.digest();
    	try {
    		String hash = new String(org.apache.commons.codec.binary.Hex.encodeHex(raw));
    		return hash;
    	} 
			catch(Exception use){
			return "";
		}
    	
    	
    }

    /**
     * @param sql The sql to set.
     */
    public void setSql(final String sql) {
        this.sql = sql;
    }
}
