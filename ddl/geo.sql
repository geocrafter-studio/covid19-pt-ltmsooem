create schema geo;

-- create regions dataset
CREATE TABLE geo.pt_regions (
	objectid int8 NOT NULL,
	"name" varchar(90) NOT NULL,
	geom geometry NOT NULL,
	CONSTRAINT pt_regions_pkey PRIMARY KEY (objectid)
);
CREATE INDEX pt_regions_geom_idx ON geo.pt_regions USING gist (geom);

-- create municipal dataset
CREATE TABLE geo.pt_mun (
	dico varchar(4) NOT NULL,
	concelho varchar(254) NOT NULL,
	geom geometry NOT NULL,
	CONSTRAINT pt_mun_pkey PRIMARY KEY (dico)
);
CREATE INDEX pt_mun_geom_idx ON geo.pt_mun USING gist (geom);
