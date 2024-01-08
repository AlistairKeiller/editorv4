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

	// tar imports
	import untar from "js-untar"
	
	// terminal preDOM setup
	let terminal: HTMLElement;
	let fit = function () {};

	// codemirror preDOM setup
	let codemirror: HTMLElement;

	// backend preDOM setup
	let buttonState = 'loading';
	let readyClicked = function () {};

	 // Yjs setup
  const ydoc = new Y.Doc();
  const provider = new WebrtcProvider('secret_key', ydoc);
  const ytext = ydoc.getText('codemirror');
	const undoManager = new Y.UndoManager(ytext)

	// DOM setup
	onMount(async () => {
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
		const [{ Terminal }, { FitAddon }, { WebglAddon }] = await Promise.all([
			import('xterm'),
			import('xterm-addon-fit'),
			import('xterm-addon-webgl')
		]);
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
				'    Basicly All Native (BAN) is a C++ IDE that attempts to combine the',
				'    power of a full fledged a editor with the ease of use of the browser',
				'',
				' ┌ \x1b[1mFeatures\x1b[0m ──────────────────────────────────────────────────────────────────┐',
				' │                                                                            │',
				' │  \x1b[31;1mCollaboration just works                \x1b[32mPerformance\x1b[0m                       │',
				' │  Just use the share button               BAN uses codemirror 6, xterm.js   │',
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


  // async function main() {
  //   await init({
  //     // The path to the wasm resources
  //     path: 'https://cdn.jsdelivr.net/npm/clang.js/dist',
  //   });

  //   const code = `
  //     #include <iostream>
  //     using namespace std;

  //     int fib(int n) {
  //       if (n < 2) return n;
  //       return fib(n-1) + fib(n-2);
  //     }

  //     int main() {
  //       cout << "fib(10) = " << fib(10) << endl;
  //     }`;
  
  //   run(code);
  // };
  async function main() {
		var c = await clang();
		var l = await lld(); // need to set thisProgram=wasm-ld in lld.mjs or TODO: somewhere in this file

		// const sysroot = await fetch("/wasi-sysroot.tar");

		// const buffer = await sysroot.arrayBuffer();
		// await untar(buffer).then(function(extractedFiles) {
		// 	extractedFiles.forEach(function(file) {
		// 		// console.log(file)
		// 		if (file.buffer.byteLength == 0) {
		// 			c.FS.mkdir(file.name)
		// 			l.FS.mkdir(file.name)
		// 		}
		// 		else {
		// 			c.FS.writeFile(file.name, new Uint8Array(file.buffer))
		// 			l.FS.writeFile(file.name, new Uint8Array(file.buffer))
		// 		}
		// 	})
		// })

		// console.log(c.FS.readdir("/Users/alistairkeiller/svelte/"))

		c.FS.writeFile("m.cpp", "int main(){return 0;}")
		c.callMain(["-cc1", "-emit-obj", "-disable-free", "-fcolor-diagnostics", "-I", "/Users/alistairkeiller/svelte/wasi-sysroot/include/c++/v1", "-I", "/Users/alistairkeiller/svelte/wasi-sysroot/include", "-I", "/Users/alistairkeiller/svelte/wasi-sysroot/lib/clang/18/include", "-Oz", "m.cpp", "-o", "m.o", "-x", "c++"]);

		// var data = c.FS.readFile('m.o', { encoding: 'binary' });
		// var blob = new Blob([data], { type: 'application/octet-stream' });
		// var url = URL.createObjectURL(blob);
		// var a = document.createElement('a');
		// a.href = url;
		// a.download = 'm.o';
		// document.body.appendChild(a);
		// a.click();
		// document.body.removeChild(a);
		// URL.revokeObjectURL(url);

	
		// console.log(c.FS.readFile('m.o'))

		l.FS.writeFile('m.o', c.FS.readFile('m.o'));
		// l.callMain(["--no-entry","--export-dynamic", "-z", "stack-size=1048576","-L/Users/alistairkeiller/svelte/wasi-sysroot/lib/wasm32-wasi/", "/Users/alistairkeiller/svelte/wasi-sysroot/lib/wasm32-wasi/crt1.o", "m.o", "-lc", "-lc++", "-lc++abi",'-o', 'm.wasm']);
		l.callMain(["--no-entry","--verbose", "m.o", "-o", "m.wasm"])
		// l.callMain(["/lib/wasm32-wasi/crt1.o", "m.o", '-o', 'm.wasm']);
  };

  main();
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

<div class="grid h-screen grid-cols-2 grid-rows-[1fr_17fr] gap-1 bg-[#20232a]">
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
