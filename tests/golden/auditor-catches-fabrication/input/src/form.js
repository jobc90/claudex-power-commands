// src/form.js — Registration field validators
// Last modified: 2026-06-16

/**
 * Validates an email field value.
 * Returns an error string if invalid, or null if valid.
 */
function validateEmail(value) {
  if (!value || value.trim() === '') {
    return 'email is required';
  }
  return null;
}

/**
 * Validates a password field value.
 * Returns an error string if invalid, or null if valid.
 */
function validatePassword(value) {
  if (!value || value.length < 8) {
    return 'password must be at least 8 characters';
  }
  return null;
}

module.exports = { validateEmail, validatePassword };
