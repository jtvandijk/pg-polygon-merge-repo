#!/bin/bash

# postgres credentials
h=$1								# host
p=$2								# port
d=$3								# database
u=$4								# username

# table parameters
schema=$5						# pg schema
base_table=$6 			# input table name
merg_table=$7				#	output table name

# column names
gid=$8							# unique identifier
geom=$9							# geometry column (polygon, projected)
cent=${10}					# centroid column (polygon centroid, projected)
var=${11}						# field to decide if polygon requires to be merged

# union parameters
val=${12}						# minimum value to decide if polygon requires to be merged

# drop sequence
drop_sequence () {
psql -h $h -p $p -d $d -U $u -c "
	DROP SEQUENCE IF EXISTS $schema.union_seq;
"
}
# create sequence
create_sequence () {
		psql -h $h -p $p -d $d -U $u -c "
		CREATE SEQUENCE $schema.union_seq
		  INCREMENT 1
		  MINVALUE 1
		  MAXVALUE 99999999999999999
		  START 1
		  CACHE 1;"
}
# create merge table
create_table () {
	psql -h $h -p $p -d $d -U $u -c "
		DROP TABLE IF EXISTS $schema.$merg_table;
		CREATE TABLE $schema.$merg_table AS
			SELECT $gid gid, $geom geom, $cent centroid, $var FROM $schema.$base_table;
		ALTER TABLE $schema.$merg_table
			ADD COLUMN nb integer;"
}
# table indices
create_indices () {
	psql -h $h -p $p -d $d -U $u -c "
		CREATE INDEX ON $schema.$merg_table (gid);
		CREATE INDEX ON $schema.$merg_table USING GIST (geom);
		CREATE INDEX ON $schema.$merg_table USING GIST (centroid);"
}
# re-index table
polygon_gid () {
	psql -h $h -p $p -d $d -U $u -c "
		-- reset sequence
		ALTER SEQUENCE $schema.union_seq RESTART WITH 1;
		-- update gid
		UPDATE $schema.$merg_table
			SET gid = nextval('$schema.union_seq');"
}
# poloygon centroid to nearest other polygon centroi
closest_centroid () {
	psql -h $h -p $p -d $d -U $u -c "
		WITH closest_centroid AS (
			SELECT
				pl.gid,
				pl.centroid,
				pl.geom,
				nb.gid as nbid
			FROM $schema.$merg_table pl
			CROSS JOIN LATERAL
				(SELECT gid, centroid, geom
				 FROM $schema.$merg_table cmp
				 -- exclude comparison to self
				 WHERE pl.gid != cmp.gid
				 -- ensure polygons share boundary // slow
				 -- AND ST_Distance(pl.geom,cmp.geom) = 0
				 -- closest polygon
				 ORDER BY
				 	pl.centroid <-> cmp.centroid
				 LIMIT 1) AS nb)
		UPDATE $schema.$merg_table u
			SET nb = c.nbid
			FROM closest_centroid c
			WHERE c.gid = u.gid;"
}
# polygons that need to be merged
to_process () {
	psql -h $h -p $p -d $d -U $u -c "COPY (
		SELECT DISTINCT (gid)
			FROM $schema.$merg_table
			WHERE $var < $val
			) TO stdout WITH CSV;" > pl
}
# neighbour
get_nb () {
	psql -h $h -p $p -d $d -U $u -c "COPY (
			SELECT nb
				FROM $schema.$merg_table
				WHERE gid = $1
		) TO stdout WITH CSV;"
}
# get [$val]
get_val () {
	psql -h $h -p $p -d $d -U $u -c "COPY (
		SELECT SUM($var)
			FROM $schema.$merg_table
			WHERE gid = $1
			OR gid = $2
	) TO stdout WITH CSV;"
}
# merge geometries
merge_geom () {
	psql -h $h -p $p -d $d -U $u -c "
		UPDATE $schema.$merg_table
			SET gid = 999999999
			WHERE gid = $1
			OR gid = $2;
		CREATE TABLE $schema.tmp AS
			SELECT gid, ST_Union(geom) geom
			FROM $schema.$merg_table
			GROUP BY gid;
		ALTER TABLE $schema.tmp
			ADD COLUMN centroid geometry(Point,27700),
			ADD COLUMN $var integer,
			ADD COLUMN nb integer;
		UPDATE $schema.tmp
			SET centroid = ST_Centroid(geom);
		UPDATE $schema.tmp as u
			SET $var = m.$var
			FROM $schema.$merg_table m
			WHERE u.gid = m.gid;
		UPDATE $schema.tmp
				SET $var = $3
				WHERE gid = 999999999;
		DROP TABLE IF EXISTS $schema.$merg_table;
		ALTER TABLE $schema.tmp
			RENAME TO $merg_table;"
}

# while minimum [$var] within polygon not >= [$val]
loop_pg_merge () {

	# progress
	echo 'Initialise.'

	# create sequence
	drop_sequence
	create_sequence
	# create table
	create_table
	# create indices
	create_indices
	# update gid
	polygon_gid
	# update centroid
	closest_centroid
	# update process list
	to_process

	# polygon
	cnt=$(wc -l < pl)

	# loop
	while [ $cnt -gt 0 ]
	do

		# progress
		echo 'Remaining iterations:' $cnt

		# to merge
		pol=$(cat pl | awk '{if (NR<2) {print $0}}')
		nb=$(get_nb $pol)
		nv=$(get_val $pol $nb)

		# status
		echo 'Merging' $pol 'with' $nb'; new value:' $nv

		# execute merge
		merge_geom $pol $nb $nv
		# create indices
		create_indices
		# update gid
		polygon_gid
		# update centroid
		closest_centroid
		# update process list
		to_process

		# progress
		echo 'Iteration done.'

		# update count
		cnt=$(wc -l < pl)

	done

	# clean
	rm pl
	drop_sequence
}

#execute
loop_pg_merge
