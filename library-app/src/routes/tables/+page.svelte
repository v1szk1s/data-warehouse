<script>

import Table from '../Table.svelte';

</script>


<div class="grid grid-cols-2">
    <Table table="never_requested" />
    
    <Table table="most_request_student" />

    <Table table="most_request_course" />

    <Table table="most_request_gender" />

    <Table table="most_request_population" />

    <Table table="not_returned" />

    <Table table="an_new_old" />

</div>

<div class="h-1/4"></div>
