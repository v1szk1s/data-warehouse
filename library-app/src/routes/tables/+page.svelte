<script>

import Table from '../Table.svelte';

</script>


<div class="grid grid-cols-2">
    <Table table="books_not_requested" />
    
    <Table table="most_request_student" />

    <Table table="most_request_course" />

    <Table table="most_request_gender" />

    <Table table="most_request_population" />

    <Table table="not_returned" />

</div>

<div class="h-1/4"></div>
