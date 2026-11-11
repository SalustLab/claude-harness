// Run: node tests/test-brainstorming.cjs [path-to-bash]
// Uses an isolated temporary project; never opens a browser.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawn, spawnSync } = require('node:child_process');
const { once } = require('node:events');
const { createInterface } = require('node:readline');

async function main() {
    const bash = process.argv[2] || (process.platform === 'win32'
        ? 'C:/Program Files/Git/bin/bash.exe' : 'bash');
    const scripts = path.resolve(__dirname, '../claude/skills/brainstorming/scripts');
    const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'brainstorm-test-'));
    const project = path.join(temp, 'relative project');
    const env = Object.fromEntries(Object.entries(process.env).filter(([key]) =>
        !key.startsWith('BRAINSTORM_')));
    const child = spawn(bash, [path.join(scripts, 'start-server.sh'),
        '--project-dir', 'relative project', '--foreground'], { cwd: temp, env });
    let stderr = '';
    child.stderr.on('data', chunk => { stderr += chunk; });
    let info;
    const lines = createInterface({ input: child.stdout });
    try {
        info = await new Promise((resolve, reject) => {
            const timeout = setTimeout(() => reject(new Error('Startup timed out: ' + stderr)), 15000);
            const finish = callback => value => { clearTimeout(timeout); callback(value); };
            child.once('error', finish(reject));
            child.once('exit', finish(() => reject(new Error('Launcher exited: ' + stderr))));
            lines.on('line', line => {
                try {
                    const value = JSON.parse(line);
                    if (value.type === 'server-started') finish(resolve)(value);
                } catch { /* Ignore non-JSON diagnostic lines. */ }
            });
        });
        const sessions = path.join(project, '.superpowers', 'brainstorm');
        const session = fs.readdirSync(sessions).find(name =>
            fs.statSync(path.join(sessions, name)).isDirectory());
        const contentDir = path.join(sessions, session, 'content');
        assert.equal(fs.realpathSync(info.screen_dir), fs.realpathSync(contentDir),
            'Relative project paths must stay rooted in the caller directory');
        const fragment = '<p>Literal replacement tokens: $& $` $\' $$</p>';
        fs.writeFileSync(path.join(contentDir, 'literal.html'), fragment);
        const bootstrap = await fetch(info.url, { signal: AbortSignal.timeout(5000) });
        assert.equal(bootstrap.status, 200);
        const cookie = bootstrap.headers.get('set-cookie').split(';')[0];
        await bootstrap.text();
        const response = await fetch(new URL('/', info.url), {
            headers: { Cookie: cookie }, signal: AbortSignal.timeout(5000)
        });
        assert.equal(response.status, 200);
        assert.ok((await response.text()).includes(fragment),
            'HTML fragments must preserve JavaScript replacement tokens verbatim');
        console.log('PASS: relative project path with spaces; literal HTML replacement tokens');
    } finally {
        lines.close();
        if (info) {
            const result = spawnSync(bash, [path.join(scripts, 'stop-server.sh'),
                path.dirname(info.state_dir)], { encoding: 'utf8', timeout: 10000 });
            assert.equal(result.status, 0, 'Test server cleanup failed: ' + result.stderr);
        } else {
            child.kill();
        }
        if (child.exitCode === null && child.signalCode === null) {
            await Promise.race([once(child, 'exit'), new Promise(resolve => setTimeout(resolve, 2000))]);
        }
        fs.rmSync(temp, { recursive: true, force: true });
    }
}

main().catch(error => { console.error(error.message); process.exitCode = 1; });
