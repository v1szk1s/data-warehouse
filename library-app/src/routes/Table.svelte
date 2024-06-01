<script>
import { onMount } from "svelte";
export let table;

let page = 0;
let data;

$: label = data?.label;
$: titles = data?.titles;
$: rows = data?.rows;

async function update(){
    const response = await fetch('/api', {
        method: 'POST',
        body: JSON.stringify({table: table, page: page}),
        headers: {
            'Content-Type': 'application/json'
        }
    });
    data = await response.json();
}

onMount(async () => {
    await update();
})

</script>


<div class="flex flex-col gap-4 mx-atuo text-center mb-2">
    <p class="text-xl">{label ?? ""}</p>

    <div class="flex flex-col w-5/6 mx-auto">
        <div class="ms-auto">
            <button class="bg-lime-500 rounded p-1 m-1" on:click={() => {page = page > 0 ? page-1:page; update()}}>Previous</button>
            <button class="bg-lime-500 rounded p-1 m-1" on:click={() => {page += 1; update()} }>Next</button>
        </div>
        <p> Page: {page + 1} </p>

        <table class="table-auto mx-auto bg-gray-200 rounded">
            <tr>
                {#each titles ?? [] as title}
                    <td class="px-2">{title}</td>
                {/each}
            </tr>
            {#each rows ?? [] as row}
                <tr>
                    {#each titles ?? [] as title}
                        <td>
                            {typeof row[title].getMonth === "function" ? row[title].getYear:row[title]}
                        </td>
                    {/each}
                </tr>
            {/each}
        </table>
    </div>
</div>

<!-- <p>
{table}
</p> -->
<!-- <p>
{page}
</p> -->

