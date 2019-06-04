## Iteratively Merge Polygons in a Postgres/PostGIS database

#### About
Shell script (using psql) that allows you to iteratively merge (aggregate) adjacent polygons stored in a Postgres/PostGIS database by considering a minimum required value for a given variable. For instance, if you have polygons containing population data and you require all polygons to contain a minimum of 1,000 people, you can use this script to iteratively merge adjacent polygons until this threshold has been reached ('aggregation with dissolve'). With a large number of polygons to be aggregated this process may be slow. 

__Iterative steps__

The following steps are taken until all polygons meet the mimimum value requirements.

1. Copying relevant fields from input table to new (temporary) output table.
2. Creating relevant (spatial) indices.
3. Assigning unique identifiers to new (temporary) output table.
4. Finding for each polygon centroid its nearest neighbour (centroid distance).
5. Selecting the first polygon in the list of polygons (ids) that does not meet the minimum value requirements.
6. Merge selected polygon with its nearest neighbour (centroid distance) and update variable value (sum of merge).
7. Update polygon list (ids) that do not meet the minimum value requirements.
8. Repeat.

#### Usage
The script can be executed by passing __13__ arguments. Arguments simply need to be provided to a config file in the
order that is shown below. See _config_example.txt_ for an example. All arguments are required. Input table needs to be set up (including required columns) before running. 

  fn_merge_pg_polygons [arguments]
    
    # Postgres settings // input
    h           postgres server
    p           postgres port
    d           postgres database
    u           postgres username
    pw	postgres password for database
    
    # Table settings // input
    schema      name of postgres schema
    base_table  name of target table
    merg_table  name of output table
    
    # Column settings // input
    gid         column name unique identifier 
    geom        column name polygon geometry column (polygon; projected)
    cent        column name point geometry column (polygon centroid; projected)
    
    # Aggregation settings
    var         column on which to base aggregation (e.g. containing population counts)
    val         minimum threshold value (e.g. minimum of 1,000 people per polygon)

The script can be executed by passing __13__ arguments. Arguments simply need to be provided through a config file. All arguments are required. Arguments need to be in the exact order that is shown below. See _config_example.txt_ for an example. Please note that the nput table needs to be set up, including required columns, before running the script. 

    host:         postgres server
    port:         postgres port
    database:     postgres database
    username:     postgres username
    pw:           postgres password database
    schema:       name of postgres schema
    input_table:  name of target table
    output_table: name of output table
    unique_id:    column name unique identifier 
    poly_geom:    column name polygon geometry column (polygon; projected)
    poly_cent:    column name point geometry column (polygon centroid; projected)
    variable:     column on which to base aggregation (e.g. containing population counts)
    value:        minimum threshold value (e.g. minimum of 1,000 people per polygon)

#### Examples

    # Change file permissions to make file executable
    chmod +x fn_merge_pg_polygons

    # Execute
    ./fn_merge_pg_polygons server --config="config_example.txt"

#### Output
The final output is a new table table in your Postgres/PostGIS database that contains the merged polygons, all of which will have at least the desired minimum value for the variable of interest that was specified.

#### Dependencies
* __psql__ 
* __awk__

#### To do
* Speed improvements by adjusting the centroid matching process.

