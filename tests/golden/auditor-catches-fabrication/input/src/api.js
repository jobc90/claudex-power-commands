// src/api.js — User Registration API
// Last modified: 2026-06-16

const express = require('express');
const { validateEmail, validatePassword } = require('./form');

const router = express.Router();

// Health check
router.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// POST /api/register
// Accepts: { email, password }
// Returns: 201 on success, 400 on validation failure
router.post('/register', async (req, res) => {
  const { email, password } = req.body;

  const emailError = validateEmail(email);
  if (emailError) {
    return res.status(400).json({ error: emailError });
  }

  const passwordError = validatePassword(password);
  if (passwordError) {
    return res.status(400).json({ error: passwordError });
  }

  // Persist user (stubbed — DB layer out of scope)
  return res.status(201).json({ message: 'registered' });
});

module.exports = router;
