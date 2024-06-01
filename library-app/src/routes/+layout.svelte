<script>
	import '../app.css';
    import { page } from '$app/stores';

    $: activeUrl = $page.url.pathname;

</script>

<nav>
    <div class="flex justify-evenly p-3">
        <a class="text-xl p-1 rounded hover:bg-gray-700 hover:text-white {activeUrl == '/' ? 'bg-gray-300':''}" href="/">Analyzis</a>
        <a class="text-xl p-1 rounded hover:bg-gray-700 hover:text-white {activeUrl == '/tables' ? 'bg-gray-300':''}" href="/tables">Tables</a>
    </div>

</nav>
<slot></slot>

<style></style>
