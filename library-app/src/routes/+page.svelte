<script>

import { Bar } from 'svelte-chartjs';
import { Line } from 'svelte-chartjs';
import Table from './Table.svelte';

export let data;


import {
    Chart,
    Title,
    Tooltip,
    Legend,
    BarElement,
    CategoryScale,
    LinearScale,
    LineElement,
    PointElement,
} from 'chart.js';

Chart.register(
    Title,
    Tooltip,
    Legend,
    BarElement,
    CategoryScale,
    LinearScale,
    LineElement,
    LinearScale,
    PointElement,
);

</script>


<div class="flex flex-col gap-3 container mx-auto text-center">
    <p class="font-sans text-2xl py-3">
        Library Data Warehous Analyzis
    </p>
    
    <div class="grid grid-cols-2 gap-2 w-5/6 mx-auto text-center">
        {#each data.book_usages as data}
            <div>
                <p class="font-sans text-2xl py-3">
                    {data.datasets[0].label}
                </p>
                <Line { data } options={{ responsive: true }} />
            </div>
        {/each}
    
    </div>
    
    <div class="flex">
        <div class="container w-3/4 text-center mx-auto">
            <p class="font-sans text-2xl py-3">
                {data.course_request.datasets[0].label}
            </p>
            
            <Bar data={ data.course_request } options={{ responsive: true }} />
        </div>
        
        <div class="my-auto">
            <p class="font-sans text-4xl py-3">
                Average requisition time:
            </p>
            <p class="text-xl rounded bg-green-500 mx-5">
                {parseFloat(data.avg_request_time).toFixed(0)} days
            </p>
        </div>
    </div>

    <div class="container w-3/4 text-center mx-auto">
        <p class="font-sans text-2xl py-3">
            {data.readers_by_district.datasets[0].label}
        </p>
        
        <Bar data={ data.readers_by_district } options={{ responsive: true }} />
    </div>
    

</div>


