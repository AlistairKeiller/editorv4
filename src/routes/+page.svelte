<script lang="ts">
	// xterm imports
	import 'xterm/css/xterm.css';

	// codemirror imports
	import { EditorView, basicSetup } from 'codemirror';
	import { keymap } from '@codemirror/view';
	import { indentWithTab } from '@codemirror/commands';
	import { oneDark } from '@codemirror/theme-one-dark';
	import { EditorState } from '@codemirror/state';
	import { cpp } from '@codemirror/lang-cpp';

	// Yjs imports
  import * as Y from 'yjs';
  import { WebrtcProvider } from 'y-webrtc';
  import { yCollab } from 'y-codemirror.next';

	// svelte imports
	import { onMount } from 'svelte';

  // llvm imports
  import clang from '$lib/clang.mjs';
  import lld from '$lib/lld.mjs';

	// wasi imports
	import { runWasix, init } from "@wasmer/sdk";
	
	// terminal preDOM setup
	let terminal: HTMLElement;
	let fit = function () {};

	// codemirror preDOM setup
	let codemirror: HTMLElement;

	// backend preDOM setup
	let buttonState = 'loading';
	let readyClicked = function () {};


	// DOM setup
	onMount(async () => {
		 // Yjs setup
	  const ydoc = new Y.Doc();
	  const provider = new WebrtcProvider('secret_key', ydoc);
	  const ytext = ydoc.getText('codemirror');
		const undoManager = new Y.UndoManager(ytext)

		// codemirror DOM setup
		const view = new EditorView({
			state: EditorState.create({
			  doc: ytext.toString(),
    		extensions: [
    			keymap.of([indentWithTab]),
    			basicSetup,
    			cpp(),
    			EditorView.lineWrapping,
    			oneDark,
    			EditorView.theme({
    				'&': { height: '100%' },
    				'&.cm-editor': {
    					'&.cm-focused': {
    						outline: 'none'
    					}
    				},
    				'.cm-scroller::-webkit-scrollbar': { width: '12px' },
    				'.cm-scroller::-webkit-scrollbar-thumb': { backgroundColor: '#ffffff20' }
    			}),
			    yCollab(ytext, provider.awareness, { undoManager })
    		]
    	}),
			parent: codemirror
		});

		// xterm DOM setup
		const { Terminal } = await import('xterm');
		const { FitAddon } = await import('xterm-addon-fit');
		const { WebglAddon } = await import('xterm-addon-webgl');
		const xterm = new Terminal({
			theme: {
				// theme from https://github.com/Binaryify/OneDark-Pro/blob/master/src/themes/data/oneDarkPro.ts
				black: '#3f4451',
				blue: '#4aa5f0',
				brightBlack: '#4f5666',
				brightBlue: '#4dc4ff',
				brightCyan: '#4cd1e0',
				brightGreen: '#a5e075',
				brightMagenta: '#de73ff',
				brightRed: '#ff616e',
				brightWhite: '#e6e6e6',
				brightYellow: '#f0a45d',
				cyan: '#42b3c2',
				green: '#8cc265',
				magenta: '#c162de',
				red: '#e05561',
				white: '#d7dae0',
				yellow: '#d18f52',
				background: '#282c34',
				foreground: '#abb2bf'
			},
			allowProposedApi: true
		});
		xterm.open(terminal);
		const fitAddon = new FitAddon();
		xterm.loadAddon(fitAddon);
		xterm.loadAddon(new WebglAddon());
		fitAddon.fit();
		xterm.writeln(
			[
				'',
				'    C Native Editor (CNEditor) is a C++ IDE that attempts to combine the',
				'    power of a full fledged a editor with the ease of use of the browser',
				'',
				' ┌ \x1b[1mFeatures\x1b[0m ──────────────────────────────────────────────────────────────────┐',
				' │                                                                            │',
				' │  \x1b[31;1mCollaboration just works                \x1b[32mPerformance\x1b[0m                       │',
				' │  Just use the share button               CNeditor uses codemirror, xterm.js│',
				' │                                          SvelteKit, yjs, and WebAssembly   │',
				' │                                                                            │',
				' │  \x1b[33;1mAccessible                              \x1b[34mEasy to use\x1b[0m                       │',
				' │  Works on any modern browser             Anyone can use BSC                │',
				' │                                                                            │',
				' └────────────────────────────────────────────────────────────────────────────┘'
			].join('\n\r')
		);
		fit = function () {
			fitAddon.fit();
		};
		function writeToXterm(data) {
			console.log(data)
	    if (data === '\r' || data == '\n') {
	        xterm.write('\r\n');
	    } else if (data.charCodeAt(0) === 127) {
	        xterm.write('\b \b');
	    } else {
	        xterm.write(data);
	    }
		}
		xterm.onData(writeToXterm);

		await init();
		const encoder = new TextEncoder();
		buttonState = 'ready';

		readyClicked = async function () {
			try {
				buttonState = 'running';
				xterm.reset();
			let c = await clang({
				'print': function(text) { xterm.writeln(text) },
				'printErr': function(text) { xterm.writeln(text) }
			});
				c.FS.writeFile("m.cpp", view.state.doc.toString())
				c.callMain(["-cc1", "-emit-obj", "-disable-free", "-fcolor-diagnostics", "-I", "/wasi-sysroot/include/c++/v1", "-I", "/wasi-sysroot/include", "-I", "/wasi-sysroot/lib/clang/18/include", "-Oz", "m.cpp", "-o", "m.o", "-x", "c++"]);

			let l = await lld({
				"thisProgram": "wasm-ld",
				'print': function(text) { xterm.writeln(text) },
				'printErr': function(text) { xterm.writeln(text) }
			});
				l.FS.writeFile('m.o', c.FS.readFile('m.o'));
				l.callMain(["-L/wasi-sysroot/lib/wasm32-wasi/","/wasi-sysroot/lib/wasi/libclang_rt.builtins-wasm32.a", "/wasi-sysroot/lib/wasm32-wasi/crt1.o", "m.o", "-lc", "-lc++", "-lc++abi",'-o', 'm.wasm']);
				const instance = await runWasix(await WebAssembly.compile(l.FS.readFile('m.wasm')), {});
				const stdin = instance.stdin?.getWriter();
				xterm.onData(data => {
	        stdin?.write(encoder.encode(data));
				});


				instance.stdout.pipeTo(new WritableStream({ write: chunk => {chunk.forEach((c) => writeToXterm(String.fromCharCode(c)))} }));
				instance.stderr.pipeTo(new WritableStream({ write: chunk => {chunk.forEach((c) => writeToXterm(String.fromCharCode(c)))} }));
				await instance.wait();
			} catch(e) {}
			buttonState = 'ready';
		}
});
</script>

<style>
  :global(.xterm-viewport::-webkit-scrollbar) {
    width: 12px;
}
:global(.xterm-viewport::-webkit-scrollbar-thumb) {
    background-color: #ffffff20;
}
</style>

<div class="grid h-screen grid-cols-2 grid-rows-[56px_auto] gap-1 bg-[#20232a]">
	<div class="col-span-full flex justify-center mt-1">
		{#if buttonState == 'ready'}
			<button
				on:click={readyClicked}
				class="bg-green-800 text-green-300 hover:bg-green-600 hover:text-white font-bold w-32 rounded-xl transition-all outline-none drop-shadow-2xl"
			>
				Run
			</button>
		{:else if buttonState == 'running'}
			<button
				class="bg-red-800 text-red-300 hover:bg-red-600 hover:text-white font-bold w-32 rounded-xl transition-all outline-none drop-shadow-2xl"
			>
				Stop
			</button>
		{:else if buttonState == 'loading'}
			<button
				class="bg-gray-800 text-gray-300 hover:bg-gray-600 hover:text-white font-bold w-32 rounded-xl transition-all outline-none drop-shadow-2xl"
			>
				Loading...
			</button>
		{/if}
	</div>
	<div bind:this={codemirror} class="bg-[#282c34]" />
	<div bind:this={terminal} class="bg-[#282c34]" />
</div>

<svelte:window on:resize={fit} />
