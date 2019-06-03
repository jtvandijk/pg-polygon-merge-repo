# Iteratively Merge Polygons in Postgres

#### About
Bash script (using psql) that allows you to iteratively merge (aggregate) adjacent polygons stored in a Postgres/PostGIS database using a minimum attribute value. 
For instance, if you have polygons containing population data and you require all polygons to contain a minimum
of 1,000 people, you can use this script to iteratively merge adjacent polygons until this threshold has been reached. With a large number of 
polygons to be aggregate this process may be slow. 

__Iterative steps__

The following steps are roughly taken until all polygons meet the mimimum value requirements.

1. Copying relevant fields from input table to new output table.
2. Creating relevant (spatial) indicees.
3. Re-indexing new output table.
4. Calcuating for each polygon centroid the nearest other centroid.
5. Selecting the first one in the list of polygons (ids) that do not pass requirements.
6. Merge selected polygon with its nearest neighbour (centroid distance).
7. Update polygon list (ids) that do not pass requirements.

#### Usage
The script can be excecuted by passing __12__ arguments. Arguments simply need to be provided in the
order that is shown below (without any flags). All argumgents are required.

  fn_merge_pg_polygons [arguments]
    
    # Postgres settings
    --host        postgres server
    --port        port
    --database    postgres database
    --username    postgres username
    
    # Table settings
    --schema      postgres schema
    --input       target table
    --output      output table
    
    # Column settings
    --gid         unique identifier 
    --geom        polygon geometry column (polygon; projected)
    --centroid    point geometry column (polygon centroid; projected)
    
    # Aggregation settings
    --variable    column on which to base aggregation (e.g. containing population counts)
    --value       minimum threshold value (e.g. minimum of 1,000 people per polygon)

#### Examples

    # Change file permissions to make file executable
    chmod +x fn_merge_pg_polygons

    # Execute
    fn_merge_pg_polygons server 8080 database username public polygons new_polygons gid geom centroid population 750

#### Dependencies
* __psql__ 
* __awk__

#### To do
* Change argument list for usage with config file.
* Speed improvements by adjusting the centroid matching process.

