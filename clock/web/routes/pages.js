'use strict';

const { Router } = require('express');
const path = require('path');

const router = Router();
const PUBLIC = path.resolve(__dirname, '../public');

router.get('/',          (_req, res) => res.sendFile(path.join(PUBLIC, 'index.html')));
router.get('/settings',  (_req, res) => res.sendFile(path.join(PUBLIC, 'settings.html')));
router.get('/converter', (_req, res) => res.sendFile(path.join(PUBLIC, 'converter.html')));
router.get('/share',     (_req, res) => res.sendFile(path.join(PUBLIC, 'converter.html')));

module.exports = router;
