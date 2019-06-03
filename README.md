## Iteratively Merge Polygons in a Postgres/PostGIS database

#### About
Shell script (using psql) that allows you to iteratively merge (aggregate) adjacent polygons stored in a Postgres/PostGIS database by considering a minimum required value for a given variable. 
For instance, if you have polygons containing population data and you require all polygons to contain a minimum
of 1,000 people, you can use this script to iteratively merge adjacent polygons until this threshold has been reached. With a large number of 
polygons to be aggregated this process may be slow. 

__Iterative steps__

The following steps are roughly taken until all polygons meet the mimimum value requirements.

1. Copying relevant fields from input table to new (temporary) output table.
2. Creating relevant (spatial) indices.
3. Assigning unique identifiers to new (temporary) output table.
4. Calcuating for each polygon centroid its nearest neighbour (centroid distance).
5. Selecting the first polygon in the list of polygons (ids) that does not meet the minimum value requirements.
6. Merge selected polygon with its nearest neighbour (centroid distance) and update value (sum of merge).
7. Update polygon list (ids) that do not meet the minimum value requirements.

#### Usage
The script can be excecuted by passing __12__ arguments. Arguments simply need to be provided in the
order that is shown below (without any flags). All argumgents are required. Input table needs to be set up (inlcuding required columns) before running.

  fn_merge_pg_polygons [arguments]
    
    # Postgres settings // input
    --host        postgres server
    --port        postgres port
    --database    postgres database
    --username    postgres username
    
    # Table settings // input
    --schema      name of postgres schema
    --input       name of target table
    --output      name of output table
    
    # Column settings // input
    --gid         column name unique identifier 
    --geom        column name polygon geometry column (polygon; projected)
    --centroid    column name point geometry column (polygon centroid; projected)
    
    # Aggregation settings
    --variable    column on which to base aggregation (e.g. containing population counts)
    --value       minimum threshold value (e.g. minimum of 1,000 people per polygon)

#### Examples

    # Change file permissions to make file executable
    chmod +x fn_merge_pg_polygons

    # Execute
    fn_merge_pg_polygons server 8080 database username public polygons new_polygons gid geom centroid population 750

#### Output
The final output is a new table table in your Postgres/PostGIS database that contains the merged polygons, all of which will have at least the mimimum value for the variable of interest that was specified.

#### Dependencies
* __psql__ 
* __awk__

#### To do
* Change argument list for usage with config file.
* Speed improvements by adjusting the centroid matching process.

