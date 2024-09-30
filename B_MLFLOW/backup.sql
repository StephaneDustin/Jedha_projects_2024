--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.4 (Debian 16.4-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: _heroku; Type: SCHEMA; Schema: -; Owner: heroku_admin
--

CREATE SCHEMA _heroku;


ALTER SCHEMA _heroku OWNER TO heroku_admin;

--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: create_ext(); Type: FUNCTION; Schema: _heroku; Owner: heroku_admin
--

CREATE FUNCTION _heroku.create_ext() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  schemaname TEXT;
  databaseowner TEXT;

  r RECORD;

BEGIN

  IF tg_tag = 'CREATE EXTENSION' and current_user != 'rds_superuser' THEN
    FOR r IN SELECT * FROM pg_event_trigger_ddl_commands()
    LOOP
        CONTINUE WHEN r.command_tag != 'CREATE EXTENSION' OR r.object_type != 'extension';

        schemaname = (
            SELECT n.nspname
            FROM pg_catalog.pg_extension AS e
            INNER JOIN pg_catalog.pg_namespace AS n
            ON e.extnamespace = n.oid
            WHERE e.oid = r.objid
        );

        databaseowner = (
            SELECT pg_catalog.pg_get_userbyid(d.datdba)
            FROM pg_catalog.pg_database d
            WHERE d.datname = current_database()
        );
        --RAISE NOTICE 'Record for event trigger %, objid: %,tag: %, current_user: %, schema: %, database_owenr: %', r.object_identity, r.objid, tg_tag, current_user, schemaname, databaseowner;
        IF r.object_identity = 'address_standardizer_data_us' THEN
            EXECUTE format('GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE %I.us_gaz TO %I;', schemaname, databaseowner);
            EXECUTE format('GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE %I.us_lex TO %I;', schemaname, databaseowner);
            EXECUTE format('GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE %I.us_rules TO %I;', schemaname, databaseowner);
        ELSIF r.object_identity = 'amcheck' THEN
            EXECUTE format('GRANT EXECUTE ON FUNCTION %I.bt_index_check TO %I;', schemaname, databaseowner);
            EXECUTE format('GRANT EXECUTE ON FUNCTION %I.bt_index_parent_check TO %I;', schemaname, databaseowner);
        ELSIF r.object_identity = 'dict_int' THEN
            EXECUTE format('ALTER TEXT SEARCH DICTIONARY %I.intdict OWNER TO %I;', schemaname, databaseowner);
        ELSIF r.object_identity = 'pg_partman' THEN
            EXECUTE format('GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE %I.part_config TO %I;', schemaname, databaseowner);
            EXECUTE format('GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE %I.part_config_sub TO %I;', schemaname, databaseowner);
            EXECUTE format('GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE %I.custom_time_partitions TO %I;', schemaname, databaseowner);
        ELSIF r.object_identity = 'pg_stat_statements' THEN
            EXECUTE format('GRANT EXECUTE ON FUNCTION %I.pg_stat_statements_reset TO %I;', schemaname, databaseowner);
        ELSIF r.object_identity = 'postgis' THEN
            PERFORM _heroku.postgis_after_create();
        ELSIF r.object_identity = 'postgis_raster' THEN
            PERFORM _heroku.postgis_after_create();
            EXECUTE format('GRANT SELECT ON TABLE %I.raster_columns TO %I;', schemaname, databaseowner);
            EXECUTE format('GRANT SELECT ON TABLE %I.raster_overviews TO %I;', schemaname, databaseowner);
        ELSIF r.object_identity = 'postgis_topology' THEN
            PERFORM _heroku.postgis_after_create();
            EXECUTE format('GRANT USAGE ON SCHEMA topology TO %I;', databaseowner);
            EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA topology TO %I;', databaseowner);
            EXECUTE format('GRANT SELECT, UPDATE, INSERT, DELETE ON ALL TABLES IN SCHEMA topology TO %I;', databaseowner);
            EXECUTE format('GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA topology TO %I;', databaseowner);
        ELSIF r.object_identity = 'postgis_tiger_geocoder' THEN
            PERFORM _heroku.postgis_after_create();
            EXECUTE format('GRANT USAGE ON SCHEMA tiger TO %I;', databaseowner);
            EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA tiger TO %I;', databaseowner);
            EXECUTE format('GRANT SELECT, UPDATE, INSERT, DELETE ON ALL TABLES IN SCHEMA tiger TO %I;', databaseowner);

            EXECUTE format('GRANT USAGE ON SCHEMA tiger_data TO %I;', databaseowner);
            EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA tiger_data TO %I;', databaseowner);
            EXECUTE format('GRANT SELECT, UPDATE, INSERT, DELETE ON ALL TABLES IN SCHEMA tiger_data TO %I;', databaseowner);
        END IF;
    END LOOP;
  END IF;
END;
$$;


ALTER FUNCTION _heroku.create_ext() OWNER TO heroku_admin;

--
-- Name: drop_ext(); Type: FUNCTION; Schema: _heroku; Owner: heroku_admin
--

CREATE FUNCTION _heroku.drop_ext() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  schemaname TEXT;
  databaseowner TEXT;

  r RECORD;

BEGIN

  IF tg_tag = 'DROP EXTENSION' and current_user != 'rds_superuser' THEN
    FOR r IN SELECT * FROM pg_event_trigger_dropped_objects()
    LOOP
      CONTINUE WHEN r.object_type != 'extension';

      databaseowner = (
            SELECT pg_catalog.pg_get_userbyid(d.datdba)
            FROM pg_catalog.pg_database d
            WHERE d.datname = current_database()
      );

      --RAISE NOTICE 'Record for event trigger %, objid: %,tag: %, current_user: %, database_owner: %, schemaname: %', r.object_identity, r.objid, tg_tag, current_user, databaseowner, r.schema_name;

      IF r.object_identity = 'postgis_topology' THEN
          EXECUTE format('DROP SCHEMA IF EXISTS topology');
      END IF;
    END LOOP;

  END IF;
END;
$$;


ALTER FUNCTION _heroku.drop_ext() OWNER TO heroku_admin;

--
-- Name: extension_before_drop(); Type: FUNCTION; Schema: _heroku; Owner: heroku_admin
--

CREATE FUNCTION _heroku.extension_before_drop() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  query TEXT;

BEGIN
  query = (SELECT current_query());

  -- RAISE NOTICE 'executing extension_before_drop: tg_event: %, tg_tag: %, current_user: %, session_user: %, query: %', tg_event, tg_tag, current_user, session_user, query;
  IF tg_tag = 'DROP EXTENSION' and not pg_has_role(session_user, 'rds_superuser', 'MEMBER') THEN
    -- DROP EXTENSION [ IF EXISTS ] name [, ...] [ CASCADE | RESTRICT ]
    IF (regexp_match(query, 'DROP\s+EXTENSION\s+(IF\s+EXISTS)?.*(plpgsql)', 'i') IS NOT NULL) THEN
      RAISE EXCEPTION 'The plpgsql extension is required for database management and cannot be dropped.';
    END IF;
  END IF;
END;
$$;


ALTER FUNCTION _heroku.extension_before_drop() OWNER TO heroku_admin;

--
-- Name: postgis_after_create(); Type: FUNCTION; Schema: _heroku; Owner: heroku_admin
--

CREATE FUNCTION _heroku.postgis_after_create() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    schemaname TEXT;
    databaseowner TEXT;
BEGIN
    schemaname = (
        SELECT n.nspname
        FROM pg_catalog.pg_extension AS e
        INNER JOIN pg_catalog.pg_namespace AS n ON e.extnamespace = n.oid
        WHERE e.extname = 'postgis'
    );
    databaseowner = (
        SELECT pg_catalog.pg_get_userbyid(d.datdba)
        FROM pg_catalog.pg_database d
        WHERE d.datname = current_database()
    );

    EXECUTE format('GRANT EXECUTE ON FUNCTION %I.st_tileenvelope TO %I;', schemaname, databaseowner);
    EXECUTE format('GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE %I.spatial_ref_sys TO %I;', schemaname, databaseowner);
END;
$$;


ALTER FUNCTION _heroku.postgis_after_create() OWNER TO heroku_admin;

--
-- Name: validate_extension(); Type: FUNCTION; Schema: _heroku; Owner: heroku_admin
--

CREATE FUNCTION _heroku.validate_extension() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$

DECLARE

  schemaname TEXT;
  r RECORD;

BEGIN

  IF tg_tag = 'CREATE EXTENSION' and current_user != 'rds_superuser' THEN
    FOR r IN SELECT * FROM pg_event_trigger_ddl_commands()
    LOOP
      CONTINUE WHEN r.command_tag != 'CREATE EXTENSION' OR r.object_type != 'extension';

      schemaname = (
        SELECT n.nspname
        FROM pg_catalog.pg_extension AS e
        INNER JOIN pg_catalog.pg_namespace AS n
        ON e.extnamespace = n.oid
        WHERE e.oid = r.objid
      );

      IF schemaname = '_heroku' THEN
        RAISE EXCEPTION 'Creating extensions in the _heroku schema is not allowed';
      END IF;
    END LOOP;
  END IF;
END;
$$;


ALTER FUNCTION _heroku.validate_extension() OWNER TO heroku_admin;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO ue6kudu0dqj9ib;

--
-- Name: datasets; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.datasets (
    dataset_uuid character varying(36) NOT NULL,
    experiment_id integer NOT NULL,
    name character varying(500) NOT NULL,
    digest character varying(36) NOT NULL,
    dataset_source_type character varying(36) NOT NULL,
    dataset_source text NOT NULL,
    dataset_schema text,
    dataset_profile text
);


ALTER TABLE public.datasets OWNER TO ue6kudu0dqj9ib;

--
-- Name: experiment_tags; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.experiment_tags (
    key character varying(250) NOT NULL,
    value character varying(5000),
    experiment_id integer NOT NULL
);


ALTER TABLE public.experiment_tags OWNER TO ue6kudu0dqj9ib;

--
-- Name: experiments; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.experiments (
    experiment_id integer NOT NULL,
    name character varying(256) NOT NULL,
    artifact_location character varying(256),
    lifecycle_stage character varying(32),
    creation_time bigint,
    last_update_time bigint,
    CONSTRAINT experiments_lifecycle_stage CHECK (((lifecycle_stage)::text = ANY ((ARRAY['active'::character varying, 'deleted'::character varying])::text[])))
);


ALTER TABLE public.experiments OWNER TO ue6kudu0dqj9ib;

--
-- Name: experiments_experiment_id_seq; Type: SEQUENCE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE SEQUENCE public.experiments_experiment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.experiments_experiment_id_seq OWNER TO ue6kudu0dqj9ib;

--
-- Name: experiments_experiment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER SEQUENCE public.experiments_experiment_id_seq OWNED BY public.experiments.experiment_id;


--
-- Name: input_tags; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.input_tags (
    input_uuid character varying(36) NOT NULL,
    name character varying(255) NOT NULL,
    value character varying(500) NOT NULL
);


ALTER TABLE public.input_tags OWNER TO ue6kudu0dqj9ib;

--
-- Name: inputs; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.inputs (
    input_uuid character varying(36) NOT NULL,
    source_type character varying(36) NOT NULL,
    source_id character varying(36) NOT NULL,
    destination_type character varying(36) NOT NULL,
    destination_id character varying(36) NOT NULL
);


ALTER TABLE public.inputs OWNER TO ue6kudu0dqj9ib;

--
-- Name: latest_metrics; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.latest_metrics (
    key character varying(250) NOT NULL,
    value double precision NOT NULL,
    "timestamp" bigint,
    step bigint NOT NULL,
    is_nan boolean NOT NULL,
    run_uuid character varying(32) NOT NULL
);


ALTER TABLE public.latest_metrics OWNER TO ue6kudu0dqj9ib;

--
-- Name: metrics; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.metrics (
    key character varying(250) NOT NULL,
    value double precision NOT NULL,
    "timestamp" bigint NOT NULL,
    run_uuid character varying(32) NOT NULL,
    step bigint DEFAULT '0'::bigint NOT NULL,
    is_nan boolean DEFAULT false NOT NULL
);


ALTER TABLE public.metrics OWNER TO ue6kudu0dqj9ib;

--
-- Name: model_version_tags; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.model_version_tags (
    key character varying(250) NOT NULL,
    value character varying(5000),
    name character varying(256) NOT NULL,
    version integer NOT NULL
);


ALTER TABLE public.model_version_tags OWNER TO ue6kudu0dqj9ib;

--
-- Name: model_versions; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.model_versions (
    name character varying(256) NOT NULL,
    version integer NOT NULL,
    creation_time bigint,
    last_updated_time bigint,
    description character varying(5000),
    user_id character varying(256),
    current_stage character varying(20),
    source character varying(500),
    run_id character varying(32),
    status character varying(20),
    status_message character varying(500),
    run_link character varying(500),
    storage_location character varying(500)
);


ALTER TABLE public.model_versions OWNER TO ue6kudu0dqj9ib;

--
-- Name: params; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.params (
    key character varying(250) NOT NULL,
    value character varying(8000) NOT NULL,
    run_uuid character varying(32) NOT NULL
);


ALTER TABLE public.params OWNER TO ue6kudu0dqj9ib;

--
-- Name: registered_model_aliases; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.registered_model_aliases (
    alias character varying(256) NOT NULL,
    version integer NOT NULL,
    name character varying(256) NOT NULL
);


ALTER TABLE public.registered_model_aliases OWNER TO ue6kudu0dqj9ib;

--
-- Name: registered_model_tags; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.registered_model_tags (
    key character varying(250) NOT NULL,
    value character varying(5000),
    name character varying(256) NOT NULL
);


ALTER TABLE public.registered_model_tags OWNER TO ue6kudu0dqj9ib;

--
-- Name: registered_models; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.registered_models (
    name character varying(256) NOT NULL,
    creation_time bigint,
    last_updated_time bigint,
    description character varying(5000)
);


ALTER TABLE public.registered_models OWNER TO ue6kudu0dqj9ib;

--
-- Name: runs; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.runs (
    run_uuid character varying(32) NOT NULL,
    name character varying(250),
    source_type character varying(20),
    source_name character varying(500),
    entry_point_name character varying(50),
    user_id character varying(256),
    status character varying(9),
    start_time bigint,
    end_time bigint,
    source_version character varying(50),
    lifecycle_stage character varying(20),
    artifact_uri character varying(200),
    experiment_id integer,
    deleted_time bigint,
    CONSTRAINT runs_lifecycle_stage CHECK (((lifecycle_stage)::text = ANY ((ARRAY['active'::character varying, 'deleted'::character varying])::text[]))),
    CONSTRAINT runs_status_check CHECK (((status)::text = ANY ((ARRAY['SCHEDULED'::character varying, 'FAILED'::character varying, 'FINISHED'::character varying, 'RUNNING'::character varying, 'KILLED'::character varying])::text[]))),
    CONSTRAINT source_type CHECK (((source_type)::text = ANY ((ARRAY['NOTEBOOK'::character varying, 'JOB'::character varying, 'LOCAL'::character varying, 'UNKNOWN'::character varying, 'PROJECT'::character varying])::text[])))
);


ALTER TABLE public.runs OWNER TO ue6kudu0dqj9ib;

--
-- Name: tags; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.tags (
    key character varying(250) NOT NULL,
    value character varying(5000),
    run_uuid character varying(32) NOT NULL
);


ALTER TABLE public.tags OWNER TO ue6kudu0dqj9ib;

--
-- Name: trace_info; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.trace_info (
    request_id character varying(50) NOT NULL,
    experiment_id integer NOT NULL,
    timestamp_ms bigint NOT NULL,
    execution_time_ms bigint,
    status character varying(50) NOT NULL
);


ALTER TABLE public.trace_info OWNER TO ue6kudu0dqj9ib;

--
-- Name: trace_request_metadata; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.trace_request_metadata (
    key character varying(250) NOT NULL,
    value character varying(8000),
    request_id character varying(50) NOT NULL
);


ALTER TABLE public.trace_request_metadata OWNER TO ue6kudu0dqj9ib;

--
-- Name: trace_tags; Type: TABLE; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE TABLE public.trace_tags (
    key character varying(250) NOT NULL,
    value character varying(8000),
    request_id character varying(50) NOT NULL
);


ALTER TABLE public.trace_tags OWNER TO ue6kudu0dqj9ib;

--
-- Name: experiments experiment_id; Type: DEFAULT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.experiments ALTER COLUMN experiment_id SET DEFAULT nextval('public.experiments_experiment_id_seq'::regclass);


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.alembic_version (version_num) FROM stdin;
5b0e9adcef9c
\.


--
-- Data for Name: datasets; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.datasets (dataset_uuid, experiment_id, name, digest, dataset_source_type, dataset_source, dataset_schema, dataset_profile) FROM stdin;
84d4a36e728f485693c852c798dba478	34	dataset	fb9e203a	code	{"tags": {"mlflow.user": "taver", "mlflow.source.name": "app.py", "mlflow.source.type": "LOCAL", "mlflow.source.git.commit": "7c000260799ab834d59bff887b983d8fe9cb1419"}}	{"mlflow_colspec": [{"type": "string", "name": "model_key", "required": true}, {"type": "long", "name": "mileage", "required": true}, {"type": "long", "name": "engine_power", "required": true}, {"type": "string", "name": "fuel", "required": true}, {"type": "string", "name": "paint_color", "required": true}, {"type": "string", "name": "car_type", "required": true}, {"type": "boolean", "name": "private_parking_available", "required": true}, {"type": "boolean", "name": "has_gps", "required": true}, {"type": "boolean", "name": "has_air_conditioning", "required": true}, {"type": "boolean", "name": "automatic_car", "required": true}, {"type": "boolean", "name": "has_getaround_connect", "required": true}, {"type": "boolean", "name": "has_speed_regulator", "required": true}, {"type": "boolean", "name": "winter_tires", "required": true}]}	{"num_rows": 3874, "num_elements": 50362}
\.


--
-- Data for Name: experiment_tags; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.experiment_tags (key, value, experiment_id) FROM stdin;
\.


--
-- Data for Name: experiments; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.experiments (experiment_id, name, artifact_location, lifecycle_stage, creation_time, last_update_time) FROM stdin;
1	test	s3://st-using-heroku/artifacts/1	active	1718110253212	1718110253212
34	Jedha-fullstack-deployment	s3://st-using-heroku/artifacts/34	active	1720913383954	1720913383954
0	Default	s3://st-using-heroku/artifacts/0	deleted	1718058192570	1721079626558
\.


--
-- Data for Name: input_tags; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.input_tags (input_uuid, name, value) FROM stdin;
4c844b8d8659474da4bccab69e2ac02e	mlflow.data.context	train
1c7defb14776448f84587b734812cc8f	mlflow.data.context	train
298b6f8de4d9499eb7345dd2a6227733	mlflow.data.context	train
f3dd279173e44d2289026c884c4508b7	mlflow.data.context	train
73db1d999637471fba6e686b5280205e	mlflow.data.context	train
2508438965674cd48208bc8334b3f432	mlflow.data.context	train
41beb11efeec460f91472542c26eecdd	mlflow.data.context	train
de2c7f5758704cb7b4ae6a264cfc2c98	mlflow.data.context	train
bb3c8ac7275547cfaebb634c90845140	mlflow.data.context	train
377bebca2f11439fb88538f3a0c5890f	mlflow.data.context	train
dc828f7a8bf64f45a4a038a4b4bd704b	mlflow.data.context	train
\.


--
-- Data for Name: inputs; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.inputs (input_uuid, source_type, source_id, destination_type, destination_id) FROM stdin;
4c844b8d8659474da4bccab69e2ac02e	DATASET	84d4a36e728f485693c852c798dba478	RUN	b69b284743bb4df991dac137880133f2
1c7defb14776448f84587b734812cc8f	DATASET	84d4a36e728f485693c852c798dba478	RUN	c58930aef8504a29a3a6aaf66530edb8
298b6f8de4d9499eb7345dd2a6227733	DATASET	84d4a36e728f485693c852c798dba478	RUN	b05d7ff648e34c6d825b0fd64cc1aba4
f3dd279173e44d2289026c884c4508b7	DATASET	84d4a36e728f485693c852c798dba478	RUN	5f7629ad6df44e9a8b7dbdf2d03b4828
73db1d999637471fba6e686b5280205e	DATASET	84d4a36e728f485693c852c798dba478	RUN	1ddab31cc48d4e25aad2d7ce961ae5a4
2508438965674cd48208bc8334b3f432	DATASET	84d4a36e728f485693c852c798dba478	RUN	7edc40a2e8884f4bb20fb57285f2ca42
41beb11efeec460f91472542c26eecdd	DATASET	84d4a36e728f485693c852c798dba478	RUN	4dab6e2063204386a67120cd7d89a126
de2c7f5758704cb7b4ae6a264cfc2c98	DATASET	84d4a36e728f485693c852c798dba478	RUN	f426490d78cb4742a9b722ba4d1c5965
bb3c8ac7275547cfaebb634c90845140	DATASET	84d4a36e728f485693c852c798dba478	RUN	ed29fad8bc174a14b96cffb5335f4f38
377bebca2f11439fb88538f3a0c5890f	DATASET	84d4a36e728f485693c852c798dba478	RUN	2f7d81bbf3024f20a76fadcc44a0b678
dc828f7a8bf64f45a4a038a4b4bd704b	DATASET	84d4a36e728f485693c852c798dba478	RUN	2778ca3251624e94b906140412365b44
\.


--
-- Data for Name: latest_metrics; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.latest_metrics (key, value, "timestamp", step, is_nan, run_uuid) FROM stdin;
Accuracy	0.7255161379760164	1720913410925	0	f	b69b284743bb4df991dac137880133f2
Accuracy	0.7254938749951372	1720913741488	0	f	c58930aef8504a29a3a6aaf66530edb8
Accuracy	0.7255161524882283	1720917794401	0	f	b05d7ff648e34c6d825b0fd64cc1aba4
Accuracy	0.7255045727394891	1720918835873	0	f	5f7629ad6df44e9a8b7dbdf2d03b4828
Accuracy	0.7255161524882283	1720945951135	0	f	1ddab31cc48d4e25aad2d7ce961ae5a4
Accuracy	0.7254938749951372	1720967847805	0	f	7edc40a2e8884f4bb20fb57285f2ca42
Accuracy	0.7255054547438764	1720968014070	0	f	4dab6e2063204386a67120cd7d89a126
Accuracy	0.7255411343623828	1720968311092	0	f	f426490d78cb4742a9b722ba4d1c5965
Accuracy	0.7255277495813364	1720994839423	0	f	ed29fad8bc174a14b96cffb5335f4f38
Accuracy	0.7255411343623829	1721073217455	0	f	2f7d81bbf3024f20a76fadcc44a0b678
training_mean_squared_error	247.55351788280487	1721077943223	0	f	2778ca3251624e94b906140412365b44
training_mean_absolute_error	10.33499532404073	1721077943223	0	f	2778ca3251624e94b906140412365b44
training_r2_score	0.7837616019129063	1721077943223	0	f	2778ca3251624e94b906140412365b44
training_root_mean_squared_error	15.733833540583962	1721077943223	0	f	2778ca3251624e94b906140412365b44
training_score	0.7837616019129063	1721077943239	0	f	2778ca3251624e94b906140412365b44
Pipeline_score_X_test	0.7255502412669886	1721077949288	0	f	2778ca3251624e94b906140412365b44
Accuracy	0.7255502412669886	1721077949454	0	f	2778ca3251624e94b906140412365b44
\.


--
-- Data for Name: metrics; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.metrics (key, value, "timestamp", run_uuid, step, is_nan) FROM stdin;
Accuracy	0.7255161379760164	1720913410925	b69b284743bb4df991dac137880133f2	0	f
Accuracy	0.7254938749951372	1720913741488	c58930aef8504a29a3a6aaf66530edb8	0	f
Accuracy	0.7255161524882283	1720917794401	b05d7ff648e34c6d825b0fd64cc1aba4	0	f
Accuracy	0.7255045727394891	1720918835873	5f7629ad6df44e9a8b7dbdf2d03b4828	0	f
Accuracy	0.7255161524882283	1720945951135	1ddab31cc48d4e25aad2d7ce961ae5a4	0	f
Accuracy	0.7254938749951372	1720967847805	7edc40a2e8884f4bb20fb57285f2ca42	0	f
Accuracy	0.7255054547438764	1720968014070	4dab6e2063204386a67120cd7d89a126	0	f
Accuracy	0.7255411343623828	1720968311092	f426490d78cb4742a9b722ba4d1c5965	0	f
Accuracy	0.7255277495813364	1720994839423	ed29fad8bc174a14b96cffb5335f4f38	0	f
Accuracy	0.7255411343623829	1721073217455	2f7d81bbf3024f20a76fadcc44a0b678	0	f
training_mean_squared_error	247.55351788280487	1721077943223	2778ca3251624e94b906140412365b44	0	f
training_mean_absolute_error	10.33499532404073	1721077943223	2778ca3251624e94b906140412365b44	0	f
training_r2_score	0.7837616019129063	1721077943223	2778ca3251624e94b906140412365b44	0	f
training_root_mean_squared_error	15.733833540583962	1721077943223	2778ca3251624e94b906140412365b44	0	f
training_score	0.7837616019129063	1721077943239	2778ca3251624e94b906140412365b44	0	f
Pipeline_score_X_test	0.7255502412669886	1721077949288	2778ca3251624e94b906140412365b44	0	f
Accuracy	0.7255502412669886	1721077949454	2778ca3251624e94b906140412365b44	0	f
\.


--
-- Data for Name: model_version_tags; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.model_version_tags (key, value, name, version) FROM stdin;
\.


--
-- Data for Name: model_versions; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.model_versions (name, version, creation_time, last_updated_time, description, user_id, current_stage, source, run_id, status, status_message, run_link, storage_location) FROM stdin;
\.


--
-- Data for Name: params; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.params (key, value, run_uuid) FROM stdin;
memory	None	b69b284743bb4df991dac137880133f2
steps	[('Preprocessing', ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])), ('Regressor', GradientBoostingRegressor())]	b69b284743bb4df991dac137880133f2
verbose	False	b69b284743bb4df991dac137880133f2
Preprocessing	ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])	b69b284743bb4df991dac137880133f2
Regressor	GradientBoostingRegressor()	b69b284743bb4df991dac137880133f2
Preprocessing__force_int_remainder_cols	True	b69b284743bb4df991dac137880133f2
Preprocessing__n_jobs	None	b69b284743bb4df991dac137880133f2
Preprocessing__remainder	drop	b69b284743bb4df991dac137880133f2
Preprocessing__sparse_threshold	0.3	b69b284743bb4df991dac137880133f2
Preprocessing__transformer_weights	None	b69b284743bb4df991dac137880133f2
Preprocessing__transformers	[('num', StandardScaler(), ['mileage', 'engine_power']), ('cat', OneHotEncoder(drop='first', handle_unknown='ignore'), ['model_key', 'fuel', 'paint_color', 'car_type', 'private_parking_available', 'has_gps', 'has_air_conditioning', 'automatic_car', 'has_getaround_connect', 'has_speed_regulator', 'winter_tires'])]	b69b284743bb4df991dac137880133f2
Preprocessing__verbose	False	b69b284743bb4df991dac137880133f2
Preprocessing__verbose_feature_names_out	True	b69b284743bb4df991dac137880133f2
Preprocessing__num	StandardScaler()	b69b284743bb4df991dac137880133f2
Preprocessing__cat	OneHotEncoder(drop='first', handle_unknown='ignore')	b69b284743bb4df991dac137880133f2
Preprocessing__num__copy	True	b69b284743bb4df991dac137880133f2
Preprocessing__num__with_mean	True	b69b284743bb4df991dac137880133f2
Preprocessing__num__with_std	True	b69b284743bb4df991dac137880133f2
Preprocessing__cat__categories	auto	b69b284743bb4df991dac137880133f2
Preprocessing__cat__drop	first	b69b284743bb4df991dac137880133f2
Preprocessing__cat__dtype	<class 'numpy.float64'>	b69b284743bb4df991dac137880133f2
Preprocessing__cat__feature_name_combiner	concat	b69b284743bb4df991dac137880133f2
Preprocessing__cat__handle_unknown	ignore	b69b284743bb4df991dac137880133f2
Preprocessing__cat__max_categories	None	b69b284743bb4df991dac137880133f2
Preprocessing__cat__min_frequency	None	b69b284743bb4df991dac137880133f2
Preprocessing__cat__sparse_output	True	b69b284743bb4df991dac137880133f2
Regressor__alpha	0.9	b69b284743bb4df991dac137880133f2
Regressor__ccp_alpha	0.0	b69b284743bb4df991dac137880133f2
Regressor__criterion	friedman_mse	b69b284743bb4df991dac137880133f2
Regressor__init	None	b69b284743bb4df991dac137880133f2
Regressor__learning_rate	0.1	b69b284743bb4df991dac137880133f2
Regressor__loss	squared_error	b69b284743bb4df991dac137880133f2
Regressor__max_depth	3	b69b284743bb4df991dac137880133f2
Regressor__max_features	None	b69b284743bb4df991dac137880133f2
Regressor__max_leaf_nodes	None	b69b284743bb4df991dac137880133f2
Regressor__min_impurity_decrease	0.0	b69b284743bb4df991dac137880133f2
Regressor__min_samples_leaf	1	b69b284743bb4df991dac137880133f2
Regressor__min_samples_split	2	b69b284743bb4df991dac137880133f2
Regressor__min_weight_fraction_leaf	0.0	b69b284743bb4df991dac137880133f2
Regressor__n_estimators	100	b69b284743bb4df991dac137880133f2
Regressor__n_iter_no_change	None	b69b284743bb4df991dac137880133f2
Regressor__random_state	None	b69b284743bb4df991dac137880133f2
Regressor__subsample	1.0	b69b284743bb4df991dac137880133f2
Regressor__tol	0.0001	b69b284743bb4df991dac137880133f2
Regressor__validation_fraction	0.1	b69b284743bb4df991dac137880133f2
Regressor__verbose	0	b69b284743bb4df991dac137880133f2
Regressor__warm_start	False	b69b284743bb4df991dac137880133f2
memory	None	c58930aef8504a29a3a6aaf66530edb8
steps	[('Preprocessing', ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])), ('Regressor', GradientBoostingRegressor())]	c58930aef8504a29a3a6aaf66530edb8
verbose	False	c58930aef8504a29a3a6aaf66530edb8
Preprocessing	ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])	c58930aef8504a29a3a6aaf66530edb8
Regressor	GradientBoostingRegressor()	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__force_int_remainder_cols	True	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__n_jobs	None	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__remainder	drop	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__sparse_threshold	0.3	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__transformer_weights	None	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__transformers	[('num', StandardScaler(), ['mileage', 'engine_power']), ('cat', OneHotEncoder(drop='first', handle_unknown='ignore'), ['model_key', 'fuel', 'paint_color', 'car_type', 'private_parking_available', 'has_gps', 'has_air_conditioning', 'automatic_car', 'has_getaround_connect', 'has_speed_regulator', 'winter_tires'])]	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__verbose	False	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__verbose_feature_names_out	True	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__num	StandardScaler()	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__cat	OneHotEncoder(drop='first', handle_unknown='ignore')	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__num__copy	True	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__num__with_mean	True	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__num__with_std	True	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__cat__categories	auto	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__cat__drop	first	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__cat__dtype	<class 'numpy.float64'>	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__cat__feature_name_combiner	concat	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__cat__handle_unknown	ignore	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__cat__max_categories	None	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__cat__min_frequency	None	c58930aef8504a29a3a6aaf66530edb8
Preprocessing__cat__sparse_output	True	c58930aef8504a29a3a6aaf66530edb8
Regressor__alpha	0.9	c58930aef8504a29a3a6aaf66530edb8
Regressor__ccp_alpha	0.0	c58930aef8504a29a3a6aaf66530edb8
Regressor__criterion	friedman_mse	c58930aef8504a29a3a6aaf66530edb8
Regressor__init	None	c58930aef8504a29a3a6aaf66530edb8
Regressor__learning_rate	0.1	c58930aef8504a29a3a6aaf66530edb8
Regressor__loss	squared_error	c58930aef8504a29a3a6aaf66530edb8
Regressor__max_depth	3	c58930aef8504a29a3a6aaf66530edb8
Regressor__max_features	None	c58930aef8504a29a3a6aaf66530edb8
Regressor__max_leaf_nodes	None	c58930aef8504a29a3a6aaf66530edb8
Regressor__min_impurity_decrease	0.0	c58930aef8504a29a3a6aaf66530edb8
Regressor__min_samples_leaf	1	c58930aef8504a29a3a6aaf66530edb8
Regressor__min_samples_split	2	c58930aef8504a29a3a6aaf66530edb8
Regressor__min_weight_fraction_leaf	0.0	c58930aef8504a29a3a6aaf66530edb8
Regressor__n_estimators	100	c58930aef8504a29a3a6aaf66530edb8
Regressor__n_iter_no_change	None	c58930aef8504a29a3a6aaf66530edb8
Regressor__random_state	None	c58930aef8504a29a3a6aaf66530edb8
Regressor__subsample	1.0	c58930aef8504a29a3a6aaf66530edb8
Regressor__tol	0.0001	c58930aef8504a29a3a6aaf66530edb8
Regressor__validation_fraction	0.1	c58930aef8504a29a3a6aaf66530edb8
Regressor__verbose	0	c58930aef8504a29a3a6aaf66530edb8
Regressor__warm_start	False	c58930aef8504a29a3a6aaf66530edb8
memory	None	b05d7ff648e34c6d825b0fd64cc1aba4
steps	[('Preprocessing', ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])), ('Regressor', GradientBoostingRegressor())]	b05d7ff648e34c6d825b0fd64cc1aba4
verbose	False	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing	ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor	GradientBoostingRegressor()	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__force_int_remainder_cols	True	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__n_jobs	None	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__remainder	drop	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__sparse_threshold	0.3	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__transformer_weights	None	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__transformers	[('num', StandardScaler(), ['mileage', 'engine_power']), ('cat', OneHotEncoder(drop='first', handle_unknown='ignore'), ['model_key', 'fuel', 'paint_color', 'car_type', 'private_parking_available', 'has_gps', 'has_air_conditioning', 'automatic_car', 'has_getaround_connect', 'has_speed_regulator', 'winter_tires'])]	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__verbose	False	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__verbose_feature_names_out	True	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__num	StandardScaler()	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__cat	OneHotEncoder(drop='first', handle_unknown='ignore')	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__num__copy	True	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__num__with_mean	True	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__num__with_std	True	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__cat__categories	auto	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__cat__drop	first	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__cat__dtype	<class 'numpy.float64'>	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__cat__feature_name_combiner	concat	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__cat__handle_unknown	ignore	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__cat__max_categories	None	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__cat__min_frequency	None	b05d7ff648e34c6d825b0fd64cc1aba4
Preprocessing__cat__sparse_output	True	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__alpha	0.9	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__ccp_alpha	0.0	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__criterion	friedman_mse	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__init	None	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__learning_rate	0.1	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__loss	squared_error	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__max_depth	3	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__max_features	None	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__max_leaf_nodes	None	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__min_impurity_decrease	0.0	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__min_samples_leaf	1	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__min_samples_split	2	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__min_weight_fraction_leaf	0.0	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__n_estimators	100	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__n_iter_no_change	None	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__random_state	None	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__subsample	1.0	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__tol	0.0001	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__validation_fraction	0.1	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__verbose	0	b05d7ff648e34c6d825b0fd64cc1aba4
Regressor__warm_start	False	b05d7ff648e34c6d825b0fd64cc1aba4
memory	None	5f7629ad6df44e9a8b7dbdf2d03b4828
steps	[('Preprocessing', ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])), ('Regressor', GradientBoostingRegressor())]	5f7629ad6df44e9a8b7dbdf2d03b4828
verbose	False	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing	ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor	GradientBoostingRegressor()	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__force_int_remainder_cols	True	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__n_jobs	None	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__remainder	drop	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__sparse_threshold	0.3	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__transformer_weights	None	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__transformers	[('num', StandardScaler(), ['mileage', 'engine_power']), ('cat', OneHotEncoder(drop='first', handle_unknown='ignore'), ['model_key', 'fuel', 'paint_color', 'car_type', 'private_parking_available', 'has_gps', 'has_air_conditioning', 'automatic_car', 'has_getaround_connect', 'has_speed_regulator', 'winter_tires'])]	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__verbose	False	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__verbose_feature_names_out	True	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__num	StandardScaler()	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__cat	OneHotEncoder(drop='first', handle_unknown='ignore')	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__num__copy	True	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__num__with_mean	True	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__num__with_std	True	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__cat__categories	auto	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__cat__drop	first	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__cat__dtype	<class 'numpy.float64'>	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__cat__feature_name_combiner	concat	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__cat__handle_unknown	ignore	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__cat__max_categories	None	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__cat__min_frequency	None	5f7629ad6df44e9a8b7dbdf2d03b4828
Preprocessing__cat__sparse_output	True	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__alpha	0.9	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__ccp_alpha	0.0	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__criterion	friedman_mse	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__init	None	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__learning_rate	0.1	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__loss	squared_error	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__max_depth	3	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__max_features	None	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__max_leaf_nodes	None	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__min_impurity_decrease	0.0	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__min_samples_leaf	1	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__min_samples_split	2	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__min_weight_fraction_leaf	0.0	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__n_estimators	100	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__n_iter_no_change	None	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__random_state	None	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__subsample	1.0	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__tol	0.0001	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__validation_fraction	0.1	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__verbose	0	5f7629ad6df44e9a8b7dbdf2d03b4828
Regressor__warm_start	False	5f7629ad6df44e9a8b7dbdf2d03b4828
memory	None	1ddab31cc48d4e25aad2d7ce961ae5a4
steps	[('Preprocessing', ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])), ('Regressor', GradientBoostingRegressor())]	1ddab31cc48d4e25aad2d7ce961ae5a4
verbose	False	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing	ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor	GradientBoostingRegressor()	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__force_int_remainder_cols	True	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__n_jobs	None	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__remainder	drop	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__sparse_threshold	0.3	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__transformer_weights	None	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__transformers	[('num', StandardScaler(), ['mileage', 'engine_power']), ('cat', OneHotEncoder(drop='first', handle_unknown='ignore'), ['model_key', 'fuel', 'paint_color', 'car_type', 'private_parking_available', 'has_gps', 'has_air_conditioning', 'automatic_car', 'has_getaround_connect', 'has_speed_regulator', 'winter_tires'])]	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__verbose	False	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__verbose_feature_names_out	True	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__num	StandardScaler()	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__cat	OneHotEncoder(drop='first', handle_unknown='ignore')	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__num__copy	True	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__num__with_mean	True	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__num__with_std	True	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__cat__categories	auto	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__cat__drop	first	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__cat__dtype	<class 'numpy.float64'>	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__cat__feature_name_combiner	concat	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__cat__handle_unknown	ignore	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__cat__max_categories	None	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__cat__min_frequency	None	1ddab31cc48d4e25aad2d7ce961ae5a4
Preprocessing__cat__sparse_output	True	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__alpha	0.9	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__ccp_alpha	0.0	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__criterion	friedman_mse	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__init	None	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__learning_rate	0.1	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__loss	squared_error	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__max_depth	3	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__max_features	None	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__max_leaf_nodes	None	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__min_impurity_decrease	0.0	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__min_samples_leaf	1	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__min_samples_split	2	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__min_weight_fraction_leaf	0.0	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__n_estimators	100	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__n_iter_no_change	None	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__random_state	None	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__subsample	1.0	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__tol	0.0001	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__validation_fraction	0.1	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__verbose	0	1ddab31cc48d4e25aad2d7ce961ae5a4
Regressor__warm_start	False	1ddab31cc48d4e25aad2d7ce961ae5a4
memory	None	7edc40a2e8884f4bb20fb57285f2ca42
steps	[('Preprocessing', ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])), ('Regressor', GradientBoostingRegressor())]	7edc40a2e8884f4bb20fb57285f2ca42
verbose	False	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__verbose_feature_names_out	True	4dab6e2063204386a67120cd7d89a126
Preprocessing__num	StandardScaler()	4dab6e2063204386a67120cd7d89a126
Preprocessing__cat	OneHotEncoder(drop='first', handle_unknown='ignore')	4dab6e2063204386a67120cd7d89a126
Preprocessing__num__copy	True	4dab6e2063204386a67120cd7d89a126
Preprocessing	ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])	7edc40a2e8884f4bb20fb57285f2ca42
Regressor	GradientBoostingRegressor()	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__force_int_remainder_cols	True	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__n_jobs	None	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__remainder	drop	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__sparse_threshold	0.3	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__transformer_weights	None	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__transformers	[('num', StandardScaler(), ['mileage', 'engine_power']), ('cat', OneHotEncoder(drop='first', handle_unknown='ignore'), ['model_key', 'fuel', 'paint_color', 'car_type', 'private_parking_available', 'has_gps', 'has_air_conditioning', 'automatic_car', 'has_getaround_connect', 'has_speed_regulator', 'winter_tires'])]	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__verbose	False	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__verbose_feature_names_out	True	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__num	StandardScaler()	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__cat	OneHotEncoder(drop='first', handle_unknown='ignore')	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__num__copy	True	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__num__with_mean	True	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__num__with_std	True	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__cat__categories	auto	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__cat__drop	first	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__cat__dtype	<class 'numpy.float64'>	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__cat__feature_name_combiner	concat	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__cat__handle_unknown	ignore	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__cat__max_categories	None	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__cat__min_frequency	None	7edc40a2e8884f4bb20fb57285f2ca42
Preprocessing__cat__sparse_output	True	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__alpha	0.9	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__ccp_alpha	0.0	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__criterion	friedman_mse	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__init	None	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__learning_rate	0.1	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__loss	squared_error	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__max_depth	3	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__max_features	None	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__max_leaf_nodes	None	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__min_impurity_decrease	0.0	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__min_samples_leaf	1	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__min_samples_split	2	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__min_weight_fraction_leaf	0.0	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__n_estimators	100	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__n_iter_no_change	None	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__random_state	None	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__subsample	1.0	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__tol	0.0001	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__validation_fraction	0.1	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__verbose	0	7edc40a2e8884f4bb20fb57285f2ca42
Regressor__warm_start	False	7edc40a2e8884f4bb20fb57285f2ca42
memory	None	4dab6e2063204386a67120cd7d89a126
steps	[('Preprocessing', ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])), ('Regressor', GradientBoostingRegressor())]	4dab6e2063204386a67120cd7d89a126
verbose	False	4dab6e2063204386a67120cd7d89a126
Preprocessing	ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])	4dab6e2063204386a67120cd7d89a126
Regressor	GradientBoostingRegressor()	4dab6e2063204386a67120cd7d89a126
Preprocessing__force_int_remainder_cols	True	4dab6e2063204386a67120cd7d89a126
Preprocessing__n_jobs	None	4dab6e2063204386a67120cd7d89a126
Preprocessing__remainder	drop	4dab6e2063204386a67120cd7d89a126
Preprocessing__sparse_threshold	0.3	4dab6e2063204386a67120cd7d89a126
Preprocessing__transformer_weights	None	4dab6e2063204386a67120cd7d89a126
Preprocessing__transformers	[('num', StandardScaler(), ['mileage', 'engine_power']), ('cat', OneHotEncoder(drop='first', handle_unknown='ignore'), ['model_key', 'fuel', 'paint_color', 'car_type', 'private_parking_available', 'has_gps', 'has_air_conditioning', 'automatic_car', 'has_getaround_connect', 'has_speed_regulator', 'winter_tires'])]	4dab6e2063204386a67120cd7d89a126
Preprocessing__verbose	False	4dab6e2063204386a67120cd7d89a126
Preprocessing__num__with_mean	True	4dab6e2063204386a67120cd7d89a126
Preprocessing__num__with_std	True	4dab6e2063204386a67120cd7d89a126
Preprocessing__cat__categories	auto	4dab6e2063204386a67120cd7d89a126
Preprocessing__cat__drop	first	4dab6e2063204386a67120cd7d89a126
Preprocessing__cat__dtype	<class 'numpy.float64'>	4dab6e2063204386a67120cd7d89a126
Preprocessing__cat__feature_name_combiner	concat	4dab6e2063204386a67120cd7d89a126
Preprocessing__cat__handle_unknown	ignore	4dab6e2063204386a67120cd7d89a126
Preprocessing__cat__max_categories	None	4dab6e2063204386a67120cd7d89a126
Preprocessing__cat__min_frequency	None	4dab6e2063204386a67120cd7d89a126
Preprocessing__cat__sparse_output	True	4dab6e2063204386a67120cd7d89a126
Regressor__alpha	0.9	4dab6e2063204386a67120cd7d89a126
Regressor__ccp_alpha	0.0	4dab6e2063204386a67120cd7d89a126
Regressor__criterion	friedman_mse	4dab6e2063204386a67120cd7d89a126
Regressor__init	None	4dab6e2063204386a67120cd7d89a126
Regressor__learning_rate	0.1	4dab6e2063204386a67120cd7d89a126
Regressor__loss	squared_error	4dab6e2063204386a67120cd7d89a126
Regressor__max_depth	3	4dab6e2063204386a67120cd7d89a126
Regressor__max_features	None	4dab6e2063204386a67120cd7d89a126
Regressor__max_leaf_nodes	None	4dab6e2063204386a67120cd7d89a126
Regressor__min_impurity_decrease	0.0	4dab6e2063204386a67120cd7d89a126
Regressor__min_samples_leaf	1	4dab6e2063204386a67120cd7d89a126
Regressor__min_samples_split	2	4dab6e2063204386a67120cd7d89a126
Regressor__min_weight_fraction_leaf	0.0	4dab6e2063204386a67120cd7d89a126
Regressor__n_estimators	100	4dab6e2063204386a67120cd7d89a126
Regressor__n_iter_no_change	None	4dab6e2063204386a67120cd7d89a126
Regressor__random_state	None	4dab6e2063204386a67120cd7d89a126
Regressor__subsample	1.0	4dab6e2063204386a67120cd7d89a126
Regressor__tol	0.0001	4dab6e2063204386a67120cd7d89a126
Regressor__validation_fraction	0.1	4dab6e2063204386a67120cd7d89a126
Regressor__verbose	0	4dab6e2063204386a67120cd7d89a126
Regressor__warm_start	False	4dab6e2063204386a67120cd7d89a126
memory	None	f426490d78cb4742a9b722ba4d1c5965
steps	[('Preprocessing', ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])), ('Regressor', GradientBoostingRegressor())]	f426490d78cb4742a9b722ba4d1c5965
verbose	False	f426490d78cb4742a9b722ba4d1c5965
Preprocessing	ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])	f426490d78cb4742a9b722ba4d1c5965
Regressor	GradientBoostingRegressor()	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__force_int_remainder_cols	True	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__n_jobs	None	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__remainder	drop	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__sparse_threshold	0.3	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__transformer_weights	None	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__transformers	[('num', StandardScaler(), ['mileage', 'engine_power']), ('cat', OneHotEncoder(drop='first', handle_unknown='ignore'), ['model_key', 'fuel', 'paint_color', 'car_type', 'private_parking_available', 'has_gps', 'has_air_conditioning', 'automatic_car', 'has_getaround_connect', 'has_speed_regulator', 'winter_tires'])]	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__verbose	False	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__verbose_feature_names_out	True	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__num	StandardScaler()	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__cat	OneHotEncoder(drop='first', handle_unknown='ignore')	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__num__copy	True	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__num__with_mean	True	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__num__with_std	True	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__cat__categories	auto	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__cat__drop	first	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__cat__dtype	<class 'numpy.float64'>	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__cat__feature_name_combiner	concat	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__cat__handle_unknown	ignore	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__cat__max_categories	None	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__cat__min_frequency	None	f426490d78cb4742a9b722ba4d1c5965
Preprocessing__cat__sparse_output	True	f426490d78cb4742a9b722ba4d1c5965
Regressor__alpha	0.9	f426490d78cb4742a9b722ba4d1c5965
Regressor__ccp_alpha	0.0	f426490d78cb4742a9b722ba4d1c5965
Regressor__criterion	friedman_mse	f426490d78cb4742a9b722ba4d1c5965
Regressor__init	None	f426490d78cb4742a9b722ba4d1c5965
Regressor__learning_rate	0.1	f426490d78cb4742a9b722ba4d1c5965
Regressor__loss	squared_error	f426490d78cb4742a9b722ba4d1c5965
Regressor__max_depth	3	f426490d78cb4742a9b722ba4d1c5965
Regressor__max_features	None	f426490d78cb4742a9b722ba4d1c5965
Regressor__max_leaf_nodes	None	f426490d78cb4742a9b722ba4d1c5965
Regressor__min_impurity_decrease	0.0	f426490d78cb4742a9b722ba4d1c5965
Regressor__min_samples_leaf	1	f426490d78cb4742a9b722ba4d1c5965
Regressor__min_samples_split	2	f426490d78cb4742a9b722ba4d1c5965
Regressor__min_weight_fraction_leaf	0.0	f426490d78cb4742a9b722ba4d1c5965
Regressor__n_estimators	100	f426490d78cb4742a9b722ba4d1c5965
Regressor__n_iter_no_change	None	f426490d78cb4742a9b722ba4d1c5965
Regressor__random_state	None	f426490d78cb4742a9b722ba4d1c5965
Regressor__subsample	1.0	f426490d78cb4742a9b722ba4d1c5965
Regressor__tol	0.0001	f426490d78cb4742a9b722ba4d1c5965
Regressor__validation_fraction	0.1	f426490d78cb4742a9b722ba4d1c5965
Regressor__verbose	0	f426490d78cb4742a9b722ba4d1c5965
Regressor__warm_start	False	f426490d78cb4742a9b722ba4d1c5965
memory	None	ed29fad8bc174a14b96cffb5335f4f38
steps	[('Preprocessing', ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])), ('Regressor', GradientBoostingRegressor())]	ed29fad8bc174a14b96cffb5335f4f38
verbose	False	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing	ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])	ed29fad8bc174a14b96cffb5335f4f38
Regressor	GradientBoostingRegressor()	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__force_int_remainder_cols	True	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__n_jobs	None	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__remainder	drop	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__sparse_threshold	0.3	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__transformer_weights	None	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__transformers	[('num', StandardScaler(), ['mileage', 'engine_power']), ('cat', OneHotEncoder(drop='first', handle_unknown='ignore'), ['model_key', 'fuel', 'paint_color', 'car_type', 'private_parking_available', 'has_gps', 'has_air_conditioning', 'automatic_car', 'has_getaround_connect', 'has_speed_regulator', 'winter_tires'])]	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__verbose	False	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__verbose_feature_names_out	True	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__num	StandardScaler()	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__cat	OneHotEncoder(drop='first', handle_unknown='ignore')	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__num__copy	True	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__num__with_mean	True	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__num__with_std	True	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__cat__categories	auto	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__cat__drop	first	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__cat__dtype	<class 'numpy.float64'>	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__cat__feature_name_combiner	concat	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__cat__handle_unknown	ignore	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__cat__max_categories	None	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__cat__min_frequency	None	ed29fad8bc174a14b96cffb5335f4f38
Preprocessing__cat__sparse_output	True	ed29fad8bc174a14b96cffb5335f4f38
Regressor__alpha	0.9	ed29fad8bc174a14b96cffb5335f4f38
Regressor__ccp_alpha	0.0	ed29fad8bc174a14b96cffb5335f4f38
Regressor__criterion	friedman_mse	ed29fad8bc174a14b96cffb5335f4f38
Regressor__init	None	ed29fad8bc174a14b96cffb5335f4f38
Regressor__learning_rate	0.1	ed29fad8bc174a14b96cffb5335f4f38
Regressor__loss	squared_error	ed29fad8bc174a14b96cffb5335f4f38
Regressor__max_depth	3	ed29fad8bc174a14b96cffb5335f4f38
Regressor__max_features	None	ed29fad8bc174a14b96cffb5335f4f38
Regressor__max_leaf_nodes	None	ed29fad8bc174a14b96cffb5335f4f38
Regressor__min_impurity_decrease	0.0	ed29fad8bc174a14b96cffb5335f4f38
Regressor__min_samples_leaf	1	ed29fad8bc174a14b96cffb5335f4f38
Regressor__min_samples_split	2	ed29fad8bc174a14b96cffb5335f4f38
Regressor__min_weight_fraction_leaf	0.0	ed29fad8bc174a14b96cffb5335f4f38
Regressor__n_estimators	100	ed29fad8bc174a14b96cffb5335f4f38
Regressor__n_iter_no_change	None	ed29fad8bc174a14b96cffb5335f4f38
Regressor__random_state	None	ed29fad8bc174a14b96cffb5335f4f38
Regressor__subsample	1.0	ed29fad8bc174a14b96cffb5335f4f38
Regressor__tol	0.0001	ed29fad8bc174a14b96cffb5335f4f38
Regressor__validation_fraction	0.1	ed29fad8bc174a14b96cffb5335f4f38
Regressor__verbose	0	ed29fad8bc174a14b96cffb5335f4f38
Regressor__warm_start	False	ed29fad8bc174a14b96cffb5335f4f38
memory	None	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__remainder	drop	2778ca3251624e94b906140412365b44
Preprocessing__sparse_threshold	0.3	2778ca3251624e94b906140412365b44
Preprocessing__transformer_weights	None	2778ca3251624e94b906140412365b44
Preprocessing__transformers	[('num', StandardScaler(), ['mileage', 'engine_power']), ('cat', OneHotEncoder(drop='first', handle_unknown='ignore'), ['model_key', 'fuel', 'paint_color', 'car_type', 'private_parking_available', 'has_gps', 'has_air_conditioning', 'automatic_car', 'has_getaround_connect', 'has_speed_regulator', 'winter_tires'])]	2778ca3251624e94b906140412365b44
steps	[('Preprocessing', ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])), ('Regressor', GradientBoostingRegressor())]	2f7d81bbf3024f20a76fadcc44a0b678
verbose	False	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing	ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])	2f7d81bbf3024f20a76fadcc44a0b678
Regressor	GradientBoostingRegressor()	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__force_int_remainder_cols	True	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__n_jobs	None	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__remainder	drop	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__sparse_threshold	0.3	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__transformer_weights	None	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__transformers	[('num', StandardScaler(), ['mileage', 'engine_power']), ('cat', OneHotEncoder(drop='first', handle_unknown='ignore'), ['model_key', 'fuel', 'paint_color', 'car_type', 'private_parking_available', 'has_gps', 'has_air_conditioning', 'automatic_car', 'has_getaround_connect', 'has_speed_regulator', 'winter_tires'])]	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__verbose	False	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__verbose_feature_names_out	True	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__num	StandardScaler()	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__cat	OneHotEncoder(drop='first', handle_unknown='ignore')	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__num__copy	True	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__num__with_mean	True	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__num__with_std	True	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__cat__categories	auto	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__cat__drop	first	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__cat__dtype	<class 'numpy.float64'>	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__cat__feature_name_combiner	concat	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__cat__handle_unknown	ignore	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__cat__max_categories	None	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__cat__min_frequency	None	2f7d81bbf3024f20a76fadcc44a0b678
Preprocessing__cat__sparse_output	True	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__alpha	0.9	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__ccp_alpha	0.0	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__criterion	friedman_mse	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__init	None	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__learning_rate	0.1	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__loss	squared_error	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__max_depth	3	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__max_features	None	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__max_leaf_nodes	None	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__min_impurity_decrease	0.0	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__min_samples_leaf	1	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__min_samples_split	2	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__min_weight_fraction_leaf	0.0	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__n_estimators	100	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__n_iter_no_change	None	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__random_state	None	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__subsample	1.0	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__tol	0.0001	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__validation_fraction	0.1	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__verbose	0	2f7d81bbf3024f20a76fadcc44a0b678
Regressor__warm_start	False	2f7d81bbf3024f20a76fadcc44a0b678
memory	None	2778ca3251624e94b906140412365b44
steps	[('Preprocessing', ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])), ('Regressor', GradientBoostingRegressor())]	2778ca3251624e94b906140412365b44
verbose	False	2778ca3251624e94b906140412365b44
Preprocessing	ColumnTransformer(transformers=[('num', StandardScaler(),\n                                 ['mileage', 'engine_power']),\n                                ('cat',\n                                 OneHotEncoder(drop='first',\n                                               handle_unknown='ignore'),\n                                 ['model_key', 'fuel', 'paint_color',\n                                  'car_type', 'private_parking_available',\n                                  'has_gps', 'has_air_conditioning',\n                                  'automatic_car', 'has_getaround_connect',\n                                  'has_speed_regulator', 'winter_tires'])])	2778ca3251624e94b906140412365b44
Regressor	GradientBoostingRegressor()	2778ca3251624e94b906140412365b44
Preprocessing__force_int_remainder_cols	True	2778ca3251624e94b906140412365b44
Preprocessing__n_jobs	None	2778ca3251624e94b906140412365b44
Preprocessing__verbose	False	2778ca3251624e94b906140412365b44
Preprocessing__verbose_feature_names_out	True	2778ca3251624e94b906140412365b44
Preprocessing__num	StandardScaler()	2778ca3251624e94b906140412365b44
Preprocessing__cat	OneHotEncoder(drop='first', handle_unknown='ignore')	2778ca3251624e94b906140412365b44
Preprocessing__num__copy	True	2778ca3251624e94b906140412365b44
Preprocessing__num__with_mean	True	2778ca3251624e94b906140412365b44
Preprocessing__num__with_std	True	2778ca3251624e94b906140412365b44
Preprocessing__cat__categories	auto	2778ca3251624e94b906140412365b44
Preprocessing__cat__drop	first	2778ca3251624e94b906140412365b44
Preprocessing__cat__dtype	<class 'numpy.float64'>	2778ca3251624e94b906140412365b44
Preprocessing__cat__feature_name_combiner	concat	2778ca3251624e94b906140412365b44
Preprocessing__cat__handle_unknown	ignore	2778ca3251624e94b906140412365b44
Preprocessing__cat__max_categories	None	2778ca3251624e94b906140412365b44
Preprocessing__cat__min_frequency	None	2778ca3251624e94b906140412365b44
Preprocessing__cat__sparse_output	True	2778ca3251624e94b906140412365b44
Regressor__alpha	0.9	2778ca3251624e94b906140412365b44
Regressor__ccp_alpha	0.0	2778ca3251624e94b906140412365b44
Regressor__criterion	friedman_mse	2778ca3251624e94b906140412365b44
Regressor__init	None	2778ca3251624e94b906140412365b44
Regressor__learning_rate	0.1	2778ca3251624e94b906140412365b44
Regressor__loss	squared_error	2778ca3251624e94b906140412365b44
Regressor__max_depth	3	2778ca3251624e94b906140412365b44
Regressor__max_features	None	2778ca3251624e94b906140412365b44
Regressor__max_leaf_nodes	None	2778ca3251624e94b906140412365b44
Regressor__min_impurity_decrease	0.0	2778ca3251624e94b906140412365b44
Regressor__min_samples_leaf	1	2778ca3251624e94b906140412365b44
Regressor__min_samples_split	2	2778ca3251624e94b906140412365b44
Regressor__min_weight_fraction_leaf	0.0	2778ca3251624e94b906140412365b44
Regressor__n_estimators	100	2778ca3251624e94b906140412365b44
Regressor__n_iter_no_change	None	2778ca3251624e94b906140412365b44
Regressor__random_state	None	2778ca3251624e94b906140412365b44
Regressor__subsample	1.0	2778ca3251624e94b906140412365b44
Regressor__tol	0.0001	2778ca3251624e94b906140412365b44
Regressor__validation_fraction	0.1	2778ca3251624e94b906140412365b44
Regressor__verbose	0	2778ca3251624e94b906140412365b44
Regressor__warm_start	False	2778ca3251624e94b906140412365b44
\.


--
-- Data for Name: registered_model_aliases; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.registered_model_aliases (alias, version, name) FROM stdin;
\.


--
-- Data for Name: registered_model_tags; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.registered_model_tags (key, value, name) FROM stdin;
\.


--
-- Data for Name: registered_models; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.registered_models (name, creation_time, last_updated_time, description) FROM stdin;
Model_1	1721079047872	1721079047872	
\.


--
-- Data for Name: runs; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.runs (run_uuid, name, source_type, source_name, entry_point_name, user_id, status, start_time, end_time, source_version, lifecycle_stage, artifact_uri, experiment_id, deleted_time) FROM stdin;
b69b284743bb4df991dac137880133f2	sincere-conch-568	UNKNOWN			taver	FINISHED	1720913381626	1720913411046		active	s3://st-using-heroku/artifacts/34/b69b284743bb4df991dac137880133f2/artifacts	34	\N
c58930aef8504a29a3a6aaf66530edb8	treasured-ox-746	UNKNOWN			taver	FINISHED	1720913711374	1720913741612		active	s3://st-using-heroku/artifacts/34/c58930aef8504a29a3a6aaf66530edb8/artifacts	34	\N
b05d7ff648e34c6d825b0fd64cc1aba4	righteous-perch-612	UNKNOWN			taver	FINISHED	1720917765835	1720917794616		active	s3://st-using-heroku/artifacts/34/b05d7ff648e34c6d825b0fd64cc1aba4/artifacts	34	\N
5f7629ad6df44e9a8b7dbdf2d03b4828	honorable-auk-759	UNKNOWN			taver	FINISHED	1720918807900	1720918836049		active	s3://st-using-heroku/artifacts/34/5f7629ad6df44e9a8b7dbdf2d03b4828/artifacts	34	\N
1ddab31cc48d4e25aad2d7ce961ae5a4	overjoyed-ant-594	UNKNOWN			taver	FINISHED	1720945916564	1720945952150		active	s3://st-using-heroku/artifacts/34/1ddab31cc48d4e25aad2d7ce961ae5a4/artifacts	34	\N
7edc40a2e8884f4bb20fb57285f2ca42	honorable-mule-495	UNKNOWN			taver	FINISHED	1720967819083	1720967847930		active	s3://st-using-heroku/artifacts/34/7edc40a2e8884f4bb20fb57285f2ca42/artifacts	34	\N
4dab6e2063204386a67120cd7d89a126	intrigued-moth-812	UNKNOWN			taver	FINISHED	1720967985815	1720968014295		active	s3://st-using-heroku/artifacts/34/4dab6e2063204386a67120cd7d89a126/artifacts	34	\N
f426490d78cb4742a9b722ba4d1c5965	rare-deer-410	UNKNOWN			taver	FINISHED	1720968282040	1720968311277		active	s3://st-using-heroku/artifacts/34/f426490d78cb4742a9b722ba4d1c5965/artifacts	34	\N
ed29fad8bc174a14b96cffb5335f4f38	monumental-snail-320	UNKNOWN			taver	FINISHED	1720994810735	1720994839647		active	s3://st-using-heroku/artifacts/34/ed29fad8bc174a14b96cffb5335f4f38/artifacts	34	\N
2f7d81bbf3024f20a76fadcc44a0b678	flawless-panda-925	UNKNOWN			taver	FINISHED	1721073184147	1721073217712		active	s3://st-using-heroku/artifacts/34/2f7d81bbf3024f20a76fadcc44a0b678/artifacts	34	\N
2778ca3251624e94b906140412365b44	learned-fawn-562	UNKNOWN			taver	FINISHED	1721077912684	1721077949556		active	s3://st-using-heroku/artifacts/34/2778ca3251624e94b906140412365b44/artifacts	34	\N
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.tags (key, value, run_uuid) FROM stdin;
mlflow.user	taver	b69b284743bb4df991dac137880133f2
mlflow.source.name	app.py	b69b284743bb4df991dac137880133f2
mlflow.source.type	LOCAL	b69b284743bb4df991dac137880133f2
mlflow.source.git.commit	7c000260799ab834d59bff887b983d8fe9cb1419	b69b284743bb4df991dac137880133f2
mlflow.runName	sincere-conch-568	b69b284743bb4df991dac137880133f2
estimator_name	Pipeline	b69b284743bb4df991dac137880133f2
estimator_class	sklearn.pipeline.Pipeline	b69b284743bb4df991dac137880133f2
mlflow.user	taver	c58930aef8504a29a3a6aaf66530edb8
mlflow.source.name	app.py	c58930aef8504a29a3a6aaf66530edb8
mlflow.source.type	LOCAL	c58930aef8504a29a3a6aaf66530edb8
mlflow.source.git.commit	7c000260799ab834d59bff887b983d8fe9cb1419	c58930aef8504a29a3a6aaf66530edb8
mlflow.runName	treasured-ox-746	c58930aef8504a29a3a6aaf66530edb8
estimator_name	Pipeline	c58930aef8504a29a3a6aaf66530edb8
estimator_class	sklearn.pipeline.Pipeline	c58930aef8504a29a3a6aaf66530edb8
mlflow.user	taver	b05d7ff648e34c6d825b0fd64cc1aba4
mlflow.source.name	app.py	b05d7ff648e34c6d825b0fd64cc1aba4
mlflow.source.type	LOCAL	b05d7ff648e34c6d825b0fd64cc1aba4
mlflow.source.git.commit	7c000260799ab834d59bff887b983d8fe9cb1419	b05d7ff648e34c6d825b0fd64cc1aba4
mlflow.runName	righteous-perch-612	b05d7ff648e34c6d825b0fd64cc1aba4
estimator_name	Pipeline	b05d7ff648e34c6d825b0fd64cc1aba4
estimator_class	sklearn.pipeline.Pipeline	b05d7ff648e34c6d825b0fd64cc1aba4
mlflow.user	taver	5f7629ad6df44e9a8b7dbdf2d03b4828
mlflow.source.name	app.py	5f7629ad6df44e9a8b7dbdf2d03b4828
mlflow.source.type	LOCAL	5f7629ad6df44e9a8b7dbdf2d03b4828
mlflow.source.git.commit	7c000260799ab834d59bff887b983d8fe9cb1419	5f7629ad6df44e9a8b7dbdf2d03b4828
mlflow.runName	honorable-auk-759	5f7629ad6df44e9a8b7dbdf2d03b4828
estimator_name	Pipeline	5f7629ad6df44e9a8b7dbdf2d03b4828
estimator_class	sklearn.pipeline.Pipeline	5f7629ad6df44e9a8b7dbdf2d03b4828
mlflow.user	taver	1ddab31cc48d4e25aad2d7ce961ae5a4
mlflow.source.name	app.py	1ddab31cc48d4e25aad2d7ce961ae5a4
mlflow.source.type	LOCAL	1ddab31cc48d4e25aad2d7ce961ae5a4
mlflow.source.git.commit	7c000260799ab834d59bff887b983d8fe9cb1419	1ddab31cc48d4e25aad2d7ce961ae5a4
mlflow.runName	overjoyed-ant-594	1ddab31cc48d4e25aad2d7ce961ae5a4
estimator_name	Pipeline	1ddab31cc48d4e25aad2d7ce961ae5a4
estimator_class	sklearn.pipeline.Pipeline	1ddab31cc48d4e25aad2d7ce961ae5a4
mlflow.user	taver	7edc40a2e8884f4bb20fb57285f2ca42
mlflow.source.name	app.py	7edc40a2e8884f4bb20fb57285f2ca42
mlflow.source.type	LOCAL	7edc40a2e8884f4bb20fb57285f2ca42
mlflow.source.git.commit	7c000260799ab834d59bff887b983d8fe9cb1419	7edc40a2e8884f4bb20fb57285f2ca42
mlflow.runName	honorable-mule-495	7edc40a2e8884f4bb20fb57285f2ca42
estimator_name	Pipeline	7edc40a2e8884f4bb20fb57285f2ca42
estimator_class	sklearn.pipeline.Pipeline	7edc40a2e8884f4bb20fb57285f2ca42
mlflow.user	taver	4dab6e2063204386a67120cd7d89a126
mlflow.source.name	app.py	4dab6e2063204386a67120cd7d89a126
mlflow.source.type	LOCAL	4dab6e2063204386a67120cd7d89a126
mlflow.source.git.commit	7c000260799ab834d59bff887b983d8fe9cb1419	4dab6e2063204386a67120cd7d89a126
mlflow.runName	intrigued-moth-812	4dab6e2063204386a67120cd7d89a126
estimator_name	Pipeline	4dab6e2063204386a67120cd7d89a126
estimator_class	sklearn.pipeline.Pipeline	4dab6e2063204386a67120cd7d89a126
mlflow.user	taver	f426490d78cb4742a9b722ba4d1c5965
mlflow.source.name	app.py	f426490d78cb4742a9b722ba4d1c5965
mlflow.source.type	LOCAL	f426490d78cb4742a9b722ba4d1c5965
mlflow.source.git.commit	7c000260799ab834d59bff887b983d8fe9cb1419	f426490d78cb4742a9b722ba4d1c5965
mlflow.runName	rare-deer-410	f426490d78cb4742a9b722ba4d1c5965
estimator_name	Pipeline	f426490d78cb4742a9b722ba4d1c5965
estimator_class	sklearn.pipeline.Pipeline	f426490d78cb4742a9b722ba4d1c5965
mlflow.user	taver	ed29fad8bc174a14b96cffb5335f4f38
mlflow.source.name	app.py	ed29fad8bc174a14b96cffb5335f4f38
mlflow.source.type	LOCAL	ed29fad8bc174a14b96cffb5335f4f38
mlflow.source.git.commit	7c000260799ab834d59bff887b983d8fe9cb1419	ed29fad8bc174a14b96cffb5335f4f38
mlflow.runName	monumental-snail-320	ed29fad8bc174a14b96cffb5335f4f38
estimator_name	Pipeline	ed29fad8bc174a14b96cffb5335f4f38
estimator_class	sklearn.pipeline.Pipeline	ed29fad8bc174a14b96cffb5335f4f38
mlflow.user	taver	2f7d81bbf3024f20a76fadcc44a0b678
mlflow.source.name	app.py	2f7d81bbf3024f20a76fadcc44a0b678
mlflow.source.type	LOCAL	2f7d81bbf3024f20a76fadcc44a0b678
mlflow.source.git.commit	7c000260799ab834d59bff887b983d8fe9cb1419	2f7d81bbf3024f20a76fadcc44a0b678
mlflow.runName	flawless-panda-925	2f7d81bbf3024f20a76fadcc44a0b678
estimator_name	Pipeline	2f7d81bbf3024f20a76fadcc44a0b678
estimator_class	sklearn.pipeline.Pipeline	2f7d81bbf3024f20a76fadcc44a0b678
mlflow.user	taver	2778ca3251624e94b906140412365b44
mlflow.source.name	app.py	2778ca3251624e94b906140412365b44
mlflow.source.type	LOCAL	2778ca3251624e94b906140412365b44
mlflow.source.git.commit	7c000260799ab834d59bff887b983d8fe9cb1419	2778ca3251624e94b906140412365b44
mlflow.runName	learned-fawn-562	2778ca3251624e94b906140412365b44
estimator_name	Pipeline	2778ca3251624e94b906140412365b44
estimator_class	sklearn.pipeline.Pipeline	2778ca3251624e94b906140412365b44
mlflow.log-model.history	[{"run_id": "2778ca3251624e94b906140412365b44", "artifact_path": "model", "utc_time_created": "2024-07-15 21:12:24.827407", "flavors": {"python_function": {"model_path": "model.pkl", "predict_fn": "predict", "loader_module": "mlflow.sklearn", "python_version": "3.11.9", "env": {"conda": "conda.yaml", "virtualenv": "python_env.yaml"}}, "sklearn": {"pickled_model": "model.pkl", "sklearn_version": "1.5.1", "serialization_format": "cloudpickle", "code": null}}, "model_uuid": "a3355ebbcf1d46bcbd1a8ac13fab611f", "mlflow_version": "2.14.3", "signature": {"inputs": "[{\\"type\\": \\"string\\", \\"name\\": \\"model_key\\", \\"required\\": true}, {\\"type\\": \\"long\\", \\"name\\": \\"mileage\\", \\"required\\": true}, {\\"type\\": \\"long\\", \\"name\\": \\"engine_power\\", \\"required\\": true}, {\\"type\\": \\"string\\", \\"name\\": \\"fuel\\", \\"required\\": true}, {\\"type\\": \\"string\\", \\"name\\": \\"paint_color\\", \\"required\\": true}, {\\"type\\": \\"string\\", \\"name\\": \\"car_type\\", \\"required\\": true}, {\\"type\\": \\"boolean\\", \\"name\\": \\"private_parking_available\\", \\"required\\": true}, {\\"type\\": \\"boolean\\", \\"name\\": \\"has_gps\\", \\"required\\": true}, {\\"type\\": \\"boolean\\", \\"name\\": \\"has_air_conditioning\\", \\"required\\": true}, {\\"type\\": \\"boolean\\", \\"name\\": \\"automatic_car\\", \\"required\\": true}, {\\"type\\": \\"boolean\\", \\"name\\": \\"has_getaround_connect\\", \\"required\\": true}, {\\"type\\": \\"boolean\\", \\"name\\": \\"has_speed_regulator\\", \\"required\\": true}, {\\"type\\": \\"boolean\\", \\"name\\": \\"winter_tires\\", \\"required\\": true}]", "outputs": "[{\\"type\\": \\"tensor\\", \\"tensor-spec\\": {\\"dtype\\": \\"float64\\", \\"shape\\": [-1]}}]", "params": null}, "model_size_bytes": 143114}]	2778ca3251624e94b906140412365b44
\.


--
-- Data for Name: trace_info; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.trace_info (request_id, experiment_id, timestamp_ms, execution_time_ms, status) FROM stdin;
\.


--
-- Data for Name: trace_request_metadata; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.trace_request_metadata (key, value, request_id) FROM stdin;
\.


--
-- Data for Name: trace_tags; Type: TABLE DATA; Schema: public; Owner: ue6kudu0dqj9ib
--

COPY public.trace_tags (key, value, request_id) FROM stdin;
\.


--
-- Name: experiments_experiment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ue6kudu0dqj9ib
--

SELECT pg_catalog.setval('public.experiments_experiment_id_seq', 66, true);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: datasets dataset_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT dataset_pk PRIMARY KEY (experiment_id, name, digest);


--
-- Name: experiments experiment_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.experiments
    ADD CONSTRAINT experiment_pk PRIMARY KEY (experiment_id);


--
-- Name: experiment_tags experiment_tag_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.experiment_tags
    ADD CONSTRAINT experiment_tag_pk PRIMARY KEY (key, experiment_id);


--
-- Name: experiments experiments_name_key; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.experiments
    ADD CONSTRAINT experiments_name_key UNIQUE (name);


--
-- Name: input_tags input_tags_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.input_tags
    ADD CONSTRAINT input_tags_pk PRIMARY KEY (input_uuid, name);


--
-- Name: inputs inputs_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.inputs
    ADD CONSTRAINT inputs_pk PRIMARY KEY (source_type, source_id, destination_type, destination_id);


--
-- Name: latest_metrics latest_metric_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.latest_metrics
    ADD CONSTRAINT latest_metric_pk PRIMARY KEY (key, run_uuid);


--
-- Name: metrics metric_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.metrics
    ADD CONSTRAINT metric_pk PRIMARY KEY (key, "timestamp", step, run_uuid, value, is_nan);


--
-- Name: model_versions model_version_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.model_versions
    ADD CONSTRAINT model_version_pk PRIMARY KEY (name, version);


--
-- Name: model_version_tags model_version_tag_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.model_version_tags
    ADD CONSTRAINT model_version_tag_pk PRIMARY KEY (key, name, version);


--
-- Name: params param_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.params
    ADD CONSTRAINT param_pk PRIMARY KEY (key, run_uuid);


--
-- Name: registered_model_aliases registered_model_alias_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.registered_model_aliases
    ADD CONSTRAINT registered_model_alias_pk PRIMARY KEY (name, alias);


--
-- Name: registered_models registered_model_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.registered_models
    ADD CONSTRAINT registered_model_pk PRIMARY KEY (name);


--
-- Name: registered_model_tags registered_model_tag_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.registered_model_tags
    ADD CONSTRAINT registered_model_tag_pk PRIMARY KEY (key, name);


--
-- Name: runs run_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.runs
    ADD CONSTRAINT run_pk PRIMARY KEY (run_uuid);


--
-- Name: tags tag_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tag_pk PRIMARY KEY (key, run_uuid);


--
-- Name: trace_info trace_info_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.trace_info
    ADD CONSTRAINT trace_info_pk PRIMARY KEY (request_id);


--
-- Name: trace_request_metadata trace_request_metadata_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.trace_request_metadata
    ADD CONSTRAINT trace_request_metadata_pk PRIMARY KEY (key, request_id);


--
-- Name: trace_tags trace_tag_pk; Type: CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.trace_tags
    ADD CONSTRAINT trace_tag_pk PRIMARY KEY (key, request_id);


--
-- Name: index_datasets_dataset_uuid; Type: INDEX; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE INDEX index_datasets_dataset_uuid ON public.datasets USING btree (dataset_uuid);


--
-- Name: index_datasets_experiment_id_dataset_source_type; Type: INDEX; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE INDEX index_datasets_experiment_id_dataset_source_type ON public.datasets USING btree (experiment_id, dataset_source_type);


--
-- Name: index_inputs_destination_type_destination_id_source_type; Type: INDEX; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE INDEX index_inputs_destination_type_destination_id_source_type ON public.inputs USING btree (destination_type, destination_id, source_type);


--
-- Name: index_inputs_input_uuid; Type: INDEX; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE INDEX index_inputs_input_uuid ON public.inputs USING btree (input_uuid);


--
-- Name: index_latest_metrics_run_uuid; Type: INDEX; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE INDEX index_latest_metrics_run_uuid ON public.latest_metrics USING btree (run_uuid);


--
-- Name: index_metrics_run_uuid; Type: INDEX; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE INDEX index_metrics_run_uuid ON public.metrics USING btree (run_uuid);


--
-- Name: index_params_run_uuid; Type: INDEX; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE INDEX index_params_run_uuid ON public.params USING btree (run_uuid);


--
-- Name: index_tags_run_uuid; Type: INDEX; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE INDEX index_tags_run_uuid ON public.tags USING btree (run_uuid);


--
-- Name: index_trace_info_experiment_id_timestamp_ms; Type: INDEX; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE INDEX index_trace_info_experiment_id_timestamp_ms ON public.trace_info USING btree (experiment_id, timestamp_ms);


--
-- Name: index_trace_request_metadata_request_id; Type: INDEX; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE INDEX index_trace_request_metadata_request_id ON public.trace_request_metadata USING btree (request_id);


--
-- Name: index_trace_tags_request_id; Type: INDEX; Schema: public; Owner: ue6kudu0dqj9ib
--

CREATE INDEX index_trace_tags_request_id ON public.trace_tags USING btree (request_id);


--
-- Name: datasets datasets_experiment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT datasets_experiment_id_fkey FOREIGN KEY (experiment_id) REFERENCES public.experiments(experiment_id);


--
-- Name: experiment_tags experiment_tags_experiment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.experiment_tags
    ADD CONSTRAINT experiment_tags_experiment_id_fkey FOREIGN KEY (experiment_id) REFERENCES public.experiments(experiment_id);


--
-- Name: trace_info fk_trace_info_experiment_id; Type: FK CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.trace_info
    ADD CONSTRAINT fk_trace_info_experiment_id FOREIGN KEY (experiment_id) REFERENCES public.experiments(experiment_id);


--
-- Name: trace_request_metadata fk_trace_request_metadata_request_id; Type: FK CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.trace_request_metadata
    ADD CONSTRAINT fk_trace_request_metadata_request_id FOREIGN KEY (request_id) REFERENCES public.trace_info(request_id) ON DELETE CASCADE;


--
-- Name: trace_tags fk_trace_tags_request_id; Type: FK CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.trace_tags
    ADD CONSTRAINT fk_trace_tags_request_id FOREIGN KEY (request_id) REFERENCES public.trace_info(request_id) ON DELETE CASCADE;


--
-- Name: latest_metrics latest_metrics_run_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.latest_metrics
    ADD CONSTRAINT latest_metrics_run_uuid_fkey FOREIGN KEY (run_uuid) REFERENCES public.runs(run_uuid);


--
-- Name: metrics metrics_run_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.metrics
    ADD CONSTRAINT metrics_run_uuid_fkey FOREIGN KEY (run_uuid) REFERENCES public.runs(run_uuid);


--
-- Name: model_version_tags model_version_tags_name_version_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.model_version_tags
    ADD CONSTRAINT model_version_tags_name_version_fkey FOREIGN KEY (name, version) REFERENCES public.model_versions(name, version) ON UPDATE CASCADE;


--
-- Name: model_versions model_versions_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.model_versions
    ADD CONSTRAINT model_versions_name_fkey FOREIGN KEY (name) REFERENCES public.registered_models(name) ON UPDATE CASCADE;


--
-- Name: params params_run_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.params
    ADD CONSTRAINT params_run_uuid_fkey FOREIGN KEY (run_uuid) REFERENCES public.runs(run_uuid);


--
-- Name: registered_model_aliases registered_model_alias_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.registered_model_aliases
    ADD CONSTRAINT registered_model_alias_name_fkey FOREIGN KEY (name) REFERENCES public.registered_models(name) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: registered_model_tags registered_model_tags_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.registered_model_tags
    ADD CONSTRAINT registered_model_tags_name_fkey FOREIGN KEY (name) REFERENCES public.registered_models(name) ON UPDATE CASCADE;


--
-- Name: runs runs_experiment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.runs
    ADD CONSTRAINT runs_experiment_id_fkey FOREIGN KEY (experiment_id) REFERENCES public.experiments(experiment_id);


--
-- Name: tags tags_run_uuid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ue6kudu0dqj9ib
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_run_uuid_fkey FOREIGN KEY (run_uuid) REFERENCES public.runs(run_uuid);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO ue6kudu0dqj9ib;


--
-- Name: FUNCTION pg_stat_statements_reset(userid oid, dbid oid, queryid bigint); Type: ACL; Schema: public; Owner: rdsadmin
--

GRANT ALL ON FUNCTION public.pg_stat_statements_reset(userid oid, dbid oid, queryid bigint) TO ue6kudu0dqj9ib;


--
-- Name: extension_before_drop; Type: EVENT TRIGGER; Schema: -; Owner: heroku_admin
--

CREATE EVENT TRIGGER extension_before_drop ON ddl_command_start
   EXECUTE FUNCTION _heroku.extension_before_drop();


ALTER EVENT TRIGGER extension_before_drop OWNER TO heroku_admin;

--
-- Name: log_create_ext; Type: EVENT TRIGGER; Schema: -; Owner: heroku_admin
--

CREATE EVENT TRIGGER log_create_ext ON ddl_command_end
   EXECUTE FUNCTION _heroku.create_ext();


ALTER EVENT TRIGGER log_create_ext OWNER TO heroku_admin;

--
-- Name: log_drop_ext; Type: EVENT TRIGGER; Schema: -; Owner: heroku_admin
--

CREATE EVENT TRIGGER log_drop_ext ON sql_drop
   EXECUTE FUNCTION _heroku.drop_ext();


ALTER EVENT TRIGGER log_drop_ext OWNER TO heroku_admin;

--
-- Name: validate_extension; Type: EVENT TRIGGER; Schema: -; Owner: heroku_admin
--

CREATE EVENT TRIGGER validate_extension ON ddl_command_end
   EXECUTE FUNCTION _heroku.validate_extension();


ALTER EVENT TRIGGER validate_extension OWNER TO heroku_admin;

--
-- PostgreSQL database dump complete
--

