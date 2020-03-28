CREATE SCHEMA esri;

-- daily regional data placeholder (schema to match ESRI PT datamodel to ease updates)
CREATE TABLE esri.casos_regiao (
	id serial NOT NULL,
	geom geometry(POINT, 4326) NULL,
	objectid int8 NULL,
	globalid varchar(38) NULL,
	datarel date NULL,
	distrito varchar(255) NULL,
	dist_casosconf int8 NULL,
	dist_obitos int8 NULL,
	dist_recuperados int8 NULL,
	parentglobalid varchar(38) NULL,
	creationdate date NULL,
	creator varchar(128) NULL,
	editdate date NULL,
	editor varchar(128) NULL,
	ultimoreg varchar(255) NULL,
	CONSTRAINT casos_regiao_pkey PRIMARY KEY (id)
);
CREATE INDEX casos_regiao_geom_idx ON esri.casos_regiao USING gist (geom);
