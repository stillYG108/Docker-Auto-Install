#!/usr/bin/env node

'use strict';

/**
 * docker-auto-install — CLI entry point
 *
 * Locates the bundled shell script, gates the process to Linux,
 * escalates via sudo if not already root, then spawns the installer
 * with full live output streaming.
 */

const { spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

// ─────────────────────────────────────────────────────────────
//   Colours & Glyphs (Node side — mirrors the bash theme)
// ─────────────────────────────────────────────────────────────
const R  = '\x1b[0m';
const B  = '\x1b[1m';
const C  = '\x1b[1;36m';
const RE = '\x1b[1;31m';
const Y  = '\x1b[1;33m';
const G  = '\x1b[1;32m';
const D  = '\x1b[2m';
const IT = '\x1b[3m';

const DLINE = `${C}${'═'.repeat(56)}${R}`;

function banner() {
  console.log('');
  console.log(`${C}${B}`);
  console.log('  ╔══════════════════════════════════════════════════════╗');
  console.log('  ║       T H E   D O C K E R   I N S T A L L E R      ║');
  console.log('  ║       docker-auto-install  ·  npm CLI Launcher      ║');
  console.log('  ║       Version 1.0.0  ·  Crafted with Dignity        ║');
  console.log('  ╚══════════════════════════════════════════════════════╝');
  console.log(R);
  console.log(`${D}${IT}  One does not simply install Docker. One orchestrates it.${R}`);
  console.log('');
}

function err(msg) {
  console.error('');
  console.error(`  ${RE}✘${R}  ${B}${msg}${R}`);
  console.error('');
  console.error(`  ${Y}${B}╔════════════════════════════════════════╗${R}`);
  console.error(`  ${Y}${B}║  The launch has met an untimely end.   ║${R}`);
  console.error(`  ${Y}${B}║  Kindly review the message above.      ║${R}`);
  console.error(`  ${Y}${B}╚════════════════════════════════════════╝${R}`);
  console.error('');
  process.exit(1);
}

function info(msg) {
  console.log(`  ${C}ℹ${R}  ${D}${msg}${R}`);
}

function ok(msg) {
  console.log(`  ${G}✔${R}  ${G}${B}${msg}${R}`);
}

// ─────────────────────────────────────────────────────────────
//   OS Gate — Linux only
// ─────────────────────────────────────────────────────────────
banner();

if (os.platform() !== 'linux') {
  err(
    `This package targets Linux exclusively.\n` +
    `\n` +
    `  Detected platform : ${B}${os.platform()}${R}\n` +
    `\n` +
    `  ${D}For macOS or Windows, use Docker Desktop:\n` +
    `  https://docs.docker.com/get-docker/${R}`
  );
}

ok(`Linux platform confirmed — ${os.type()} ${os.release()}`);

// ─────────────────────────────────────────────────────────────
//   Locate the bundled shell script
// ─────────────────────────────────────────────────────────────
const scriptPath = path.join(__dirname, '..', 'scripts', 'the_docker_installation.sh');

if (!fs.existsSync(scriptPath)) {
  err(
    `Bundled install script not found.\n` +
    `  Expected at: ${scriptPath}\n` +
    `  Try reinstalling: ${B}npm install -g docker-auto-install${R}`
  );
}

// ─────────────────────────────────────────────────────────────
//   Ensure the script is executable
// ─────────────────────────────────────────────────────────────
try {
  fs.chmodSync(scriptPath, 0o755);
} catch (e) {
  err(`Could not set executable permission on install script:\n  ${e.message}`);
}

// ─────────────────────────────────────────────────────────────
//   Determine invocation strategy (root vs sudo)
// ─────────────────────────────────────────────────────────────
const isRoot = typeof process.getuid === 'function' && process.getuid() === 0;

let cmd, args;

if (isRoot) {
  cmd  = 'bash';
  args = [scriptPath];
  info('Running as root — proceeding directly with honour.');
} else {
  // Verify sudo is available
  const sudoCheck = spawnSync('which', ['sudo'], { encoding: 'utf8' });

  if (sudoCheck.status !== 0) {
    err(
      `Elevated privileges are required and ${B}sudo${R} was not found.\n` +
      `  Please re-run as root:\n` +
      `  ${B}su -c "bash ${scriptPath}"${R}`
    );
  }

  cmd  = 'sudo';
  args = ['bash', scriptPath];
  info(`Elevated privileges required — invoking via ${B}sudo${R}${D}.${R}`);
}

console.log('');
console.log(DLINE);
console.log('');

// ─────────────────────────────────────────────────────────────
//   Spawn the installer — inherit stdio for live colour output
// ─────────────────────────────────────────────────────────────
const result = spawnSync(cmd, args, {
  stdio : 'inherit',
  shell : false,
});

if (result.error) {
  err(`Failed to launch the installer:\n  ${result.error.message}`);
}

// Mirror the shell script's exit code so npm/CI pipelines see failures correctly
process.exit(result.status !== null ? result.status : 1);
