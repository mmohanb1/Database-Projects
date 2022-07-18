--------------------------------------------------------
--  File created - Tuesday-April-12-2022   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Trigger DECREMENT_CLASS_SIZE
--------------------------------------------------------
CREATE OR REPLACE TRIGGER DECREMENT_CLASS_SIZE
after delete on g_enrollments
for each row
begin
update classes set class_size = class_size-1 where classid = :OLD.classid;
end;
/

--------------------------------------------------------
--  DDL for Trigger DELETE_G_STUDENT
--------------------------------------------------------

CREATE OR REPLACE TRIGGER DELETE_G_STUDENT
before delete on students
for each row
begin
delete from g_enrollments where g_b# = :OLD.b#;
end;
/
--------------------------------------------------------
--  DDL for Trigger INCREMENT_CLASS_SIZE
--------------------------------------------------------

CREATE OR REPLACE TRIGGER INCREMENT_CLASS_SIZE
after insert on g_enrollments
for each row
begin
update classes set class_size = class_size+1 where classid = :NEW.classid;
end;
/

--------------------------------------------------------
--  DDL for Trigger INSERT_INTO_LOGS_ON_G_STUDENT_ADD
--------------------------------------------------------

--CREATE OR REPLACE TRIGGER INSERT_INTO_LOGS_ON_G_STUDENT_ADD
CREATE OR REPLACE TRIGGER LOG_GSTUD_ADD
after insert on g_enrollments
for each row
begin
insert into logs values(LOG_SEQ.NEXTVAL, user, to_date(sysdate, 'yyyy/mm/dd hh24:mi:ss'), 'G_ENROLLMENTS', 'Insert', concat(concat(:NEW.g_b#,','),:NEW.classid));
end;
/

--------------------------------------------------------
--  DDL for Trigger INSERT_INTO_LOGS_ON_G_STUDENT_DELETE
--------------------------------------------------------

--CREATE OR REPLACE TRIGGER INSERT_INTO_LOGS_ON_G_STUDENT_DELETE 
CREATE OR REPLACE TRIGGER LOG_GSTUD_DEL
after delete on g_enrollments
for each row
begin
insert into logs values(LOG_SEQ.NEXTVAL, user, to_date(sysdate, 'yyyy/mm/dd hh24:mi:ss'), 'G_ENROLLMENTS', 'Delete', concat(concat(:OLD.g_b#,','),:OLD.classid));
end;
/
--------------------------------------------------------
--  DDL for Trigger INSERT_INTO_LOGS_ON_STUDENT_ADD
--------------------------------------------------------

--CREATE OR REPLACE TRIGGER INSERT_INTO_LOGS_ON_STUDENT_ADD
CREATE OR REPLACE TRIGGER LOG_STUD_ADD
after insert on students
for each row
begin
insert into logs values(LOG_SEQ.NEXTVAL, user, to_date(sysdate, 'yyyy/mm/dd hh24:mi:ss'), 'STUDENTS', 'Insert', :NEW.b#);
end;
/
--------------------------------------------------------
--  DDL for Trigger INSERT_INTO_LOGS_ON_STUDENT_DELETE
--------------------------------------------------------

--CREATE OR REPLACE TRIGGER INSERT_INTO_LOGS_ON_STUDENT_DELETE 
CREATE OR REPLACE TRIGGER LOG_STUD_DEL
after delete on students
for each row
begin
insert into logs values(LOG_SEQ.NEXTVAL, user, to_date(sysdate, 'yyyy/mm/dd hh24:mi:ss'), 'STUDENTS', 'Delete', :OLD.b#);
end;
/
--ALTER TRIGGER "INSERT_INTO_LOGS_ON_STUDENT_DELETE" ENABLE;
