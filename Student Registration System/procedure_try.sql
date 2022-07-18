set serveroutput on;
set define off;

create or replace package procedure_try as
procedure show_students(students_curs out sys_refcursor);
procedure show_courses(courses_curs out sys_refcursor);
--procedure show_prereq(prereq_curs out sys_refcursor);
procedure show_classes(classes_curs out sys_refcursor);
procedure show_course_credit(course_credit_curs out sys_refcursor);
procedure show_score_grade(score_grade_curs out sys_refcursor);
procedure show_enrollments(enrollments_curs out sys_refcursor);
procedure ENROLL_G_STUDENT(p_B# in students.B#%type, p_classid in classes.classid%type, showmessage OUT VARCHAR2);
procedure DROP_STUDENT(p_B# in students.B#%type);
procedure DROP_G_STUDENT(p_B# in students.B#%type, p_classid in classes.classid%type, showmessage OUT VARCHAR2);
procedure show_logs(logs_curs out sys_refcursor);
PROCEDURE CLASS_DATA(p_classid in classes.classid%type, showmessage OUT VARCHAR2, class_info OUT sys_refcursor);
PROCEDURE show_prereq_courses(p_dept_code in courses.dept_code%type, p_course# in courses.course#%type, showmessage OUT VARCHAR2);
end;
/

create or replace package body procedure_try as
procedure show_students(students_curs out sys_refcursor) as
begin
open students_curs for
select * from students;
end show_students;


procedure show_courses(courses_curs out sys_refcursor) as
begin
open courses_curs for
select * from courses;
end show_courses;

procedure show_classes(classes_curs out sys_refcursor) as
begin
open classes_curs for
select * from classes;
end show_classes;

procedure show_course_credit(course_credit_curs out sys_refcursor) as
begin
open course_credit_curs for
select * from course_credit;
end show_course_credit;

procedure show_score_grade(score_grade_curs out sys_refcursor) as
begin
open score_grade_curs for
select * from score_grade;
end show_score_grade;

procedure show_enrollments(enrollments_curs out sys_refcursor) as
begin
open enrollments_curs for
select * from g_enrollments;
end show_enrollments;

procedure show_logs(logs_curs out sys_refcursor) as
begin
open logs_curs for
select * from logs;
end show_logs;

PROCEDURE ENROLL_G_STUDENT(p_B# in students.B#%type, p_classid in classes.classid%type, showmessage OUT VARCHAR2) is
        cursor c1 is
                               
        select distinct pre_dept_code dept, pre_course# course# from  classes c join prerequisites p on c.dept_code = p.dept_code and c.course# = p.course# 
        where c.classid = p_classid;

                c1_rec c1%rowtype; 

            B#_invalid EXCEPTION;
            not_grad_stud EXCEPTION;
            class_invalid EXCEPTION;
            invalid_sem EXCEPTION;
            prereq_not_complete EXCEPTION;
            class_full EXCEPTION;
            already_enrolled EXCEPTION;
            more_than_five_classes EXCEPTION;
             coun1 number(10);

begin


        select count(B#) into coun1 from students where B# = p_B#;
        if coun1 = 0
        then 
        raise B#_invalid;
        end if;

        select count(g_B#) into coun1 from g_enrollments where g_B# = p_B#;
        if coun1 = 0
        then 
        raise not_grad_stud;
        end if;

        select count(classid) into coun1 from classes where classid = p_classid;
        if coun1 = 0
        then
        raise class_invalid;
        end if;

        select count(classid) into coun1 from classes where classid = p_classid and lower(semester) = 'spring' and year = 2021;
        if coun1 = 0
        then
        raise invalid_sem;
        end if;

        select count(*) into coun1 from classes where classid = p_classid and limit = class_size;
        if coun1 > 0
        then 
        raise class_full;
        end if;

        select count(1) into coun1 from g_enrollments where g_b# = p_b# and classid = p_classid;
        if coun1 > 0
        then
        raise already_enrolled;
        end if;

        select count(distinct classid) into coun1 from g_enrollments where g_b# = p_b#;
        if coun1 >= 5
        then 
        raise more_than_five_classes;
        end if;


        open c1;
        fetch c1 into c1_rec;

                if c1%found
                then
                    select count(*) into coun1 from classes c join g_enrollments e on c.classid = e.classid join score_grade sc on sc.score = e.score
                    where c.course# = c1_rec.course# and c.dept_code = c1_rec.dept and e.g_b# = p_b# and sc.lgrade in ('A', 'A-', 'B+', 'B', 'B-', 'C+', 'C');
                    if coun1 <=0
                    then
                      raise prereq_not_complete;
                    end if;
                end if;


        close c1;



        insert into g_enrollments values(p_b#, p_classid, null);

--        insert into logs values(LOG_SEQ.NEXTVAL, user, to_date(sysdate, 'yyyy/mm/dd hh24:mi:ss'), 'G_ENROLLMENTS', 'Insert', CONCAT(CONCAT(p_B#, '|'), p_CLASSID));
        commit;

exception
        when B#_invalid then
                showmessage := 'The B# is invalid.';
                dbms_output.put_line('The B# is invalid.');
        when not_grad_stud then
                showmessage := 'This is not a graduate student.';
                dbms_output.put_line('This is not a graduate student.');
        when class_invalid then
                showmessage := 'The class is invalid.';
                dbms_output.put_line('The class is invalid.');
        when invalid_sem then
                showmessage := 'Cannot enroll into a class from a previous semester.';
                dbms_output.put_line('Cannot enroll into a class from a previous semester.');
        when prereq_not_complete then
                showmessage := 'Prerequisite not satisfied.';
                dbms_output.put_line('Prerequisite not satisfied.');
        when class_full then
                showmessage := 'The class is already full.';
                dbms_output.put_line('The class is already full.');
        when already_enrolled then
                showmessage := 'The student is already in the class.';
                dbms_output.put_line('The student is already in the class.');
        when more_than_five_classes then
                showmessage := 'Students cannot be enrolled in more than five classes in the same semester.';
                dbms_output.put_line('Students cannot be enrolled in more than five classes in the same semester.');


end;


PROCEDURE DROP_G_STUDENT(p_B# in students.B#%type, p_classid in classes.classid%type, showmessage OUT VARCHAR2) is
        
             B#_invalid EXCEPTION;
            not_grad_stud EXCEPTION;
            class_invalid EXCEPTION;
            not_enrolled_in_class EXCEPTION;
            invalid_sem EXCEPTION;
            only_class EXCEPTION;

             coun1 number(10);

begin

        select count(B#) into coun1 from students where B# = p_B#;
        if coun1 = 0
        then 
        raise B#_invalid;
        end if;

        select count(g_B#) into coun1 from g_enrollments where g_B# = p_B#;
        if coun1 = 0
        then 
        raise not_grad_stud;
        end if;

        select count(classid) into coun1 from classes where classid = p_classid;
        if coun1 = 0
        then
        raise class_invalid;
        end if;

        select count(classid) into coun1 from g_enrollments where g_b# = p_b# and classid = p_classid;
        if coun1 <= 0
        then
        raise not_enrolled_in_class;
        end if;

        select count(classid) into coun1 from g_enrollments where g_b# = p_b#;
        if coun1 <= 1
        then
        raise only_class;
        end if;


        select count(classid) into coun1 from classes where classid = p_classid and lower(semester) = 'spring' and year = 2021;
        if coun1 = 0
        then
        raise invalid_sem;
        end if;

        delete from g_enrollments where g_b# = p_b# and classid = p_classid;

--        insert into logs values(LOG_SEQ.NEXTVAL, user, to_date(sysdate, 'yyyy/mm/dd hh24:mi:ss'), 'G_ENROLLMENTS', 'Delete', CONCAT(CONCAT(p_B#, '|'), p_CLASSID));
        commit;

exception
        when B#_invalid then
                showmessage := 'The B# is invalid.';
                dbms_output.put_line('The B# is invalid.');
        when not_grad_stud then
                showmessage := 'This is not a graduate student.';
                dbms_output.put_line('This is not a graduate student.');
        when class_invalid then
                showmessage := 'The class is invalid.';
                dbms_output.put_line('The class is invalid.');
        when invalid_sem then
                showmessage := 'Only enrollment in the current semester can be dropped.';
                dbms_output.put_line('Only enrollment in the current semester can be dropped.');
        when not_enrolled_in_class then
                showmessage := 'The student is not enrolled in the class.';
                dbms_output.put_line('The student is not enrolled in the class.');
        when only_class then
                showmessage := 'This is the only class for this student in Spring 2021 and cannot be dropped.';
                dbms_output.put_line('This is the only class for this student in Spring 2021 and cannot be dropped.');


end;

PROCEDURE DROP_STUDENT(p_B# in students.B#%type) is
            B#_invalid EXCEPTION;
             coun1 number(10);

begin

        select count(B#) into coun1 from students where B# = p_B#;
        if coun1 = 0
        then 
        raise B#_invalid;
        end if;

        delete from students where lower(b#) = lower(p_b#);
--        insert into logs values(LOG_SEQ.NEXTVAL, user, to_date(sysdate, 'yyyy/mm/dd hh24:mi:ss'), 'STUDENTS', 'Delete', p_b#);
        commit;

exception
        when B#_invalid then
--                showmessage := 'The B# is invalid.';
                dbms_output.put_line('The B# is invalid.');
end;


PROCEDURE CLASS_DATA(p_classid in classes.classid%type, showmessage OUT VARCHAR2,class_info OUT sys_refcursor) is
check_class int;
begin
	select count(*) into check_class from classes c where c.classid=p_classid;

if check_class=0
then
    showmessage := 'The classid is invalid';
    dbms_output.put_line('The classid is empty');

else
        open class_info for
    	select s.b#,s.first_name,s.last_name from students s, classes c, g_enrollments g where c.classid=p_classid and c.classid=g.classid and s.b#=g.g_b#;
end if;
end;


PROCEDURE show_prereq_courses(p_dept_code in courses.dept_code%type, p_course# in courses.course#%type, showmessage OUT VARCHAR2) is
                course1 prerequisites.course#%type;
                dept1 prerequisites.dept_code%type;
                course2 prerequisites.course#%type;
                dept2 prerequisites.dept_code%type;
                course3 prerequisites.course#%type;
                dept3 prerequisites.dept_code%type;

        cursor c1 is

        select distinct pre_dept_code, pre_course# from prerequisites where course# = p_course# and upper(dept_code) = upper(p_dept_code);


                cursor c2 is

        select distinct pre_dept_code, pre_course# from prerequisites where course# = course1 and dept_code = dept1;


                cursor c3 is

        select distinct pre_dept_code, pre_course# from prerequisites where course# = course2 and dept_code = dept2;



                        course#_invalid EXCEPTION;
             coun1 number(10);

begin



        select count(course#) into coun1 from courses where course# = p_course#;
        if coun1 <= 0
        then
        raise course#_invalid;
        end if;


--      showmessage := '';
        for r_c1 IN c1
                LOOP
                        dept1 := r_c1.pre_dept_code;     --CS
                        course1 := r_c1.pre_course#;     --532
--                        DBMS_OUTPUT.PUT_LINE('dept: '||dept1||', course#: '||course1);
                        showmessage := showmessage || dept1 || course1 || '|';
                                for r_c2 In c2
                                LOOP
                                        dept2 := r_c2.pre_dept_code;     --CS
                                        course2 := r_c2.pre_course#;     --432
                        --                DBMS_OUTPUT.PUT_LINE('dept: '||dept2||', course#: '||course2);
                        showmessage := showmessage || dept2 || course2 || '|';
                                        FOR r_c3 in c3
                                        loop
                                                dept3 := r_c3.pre_dept_code;     --Math,CS
                                                course3 := r_c3.pre_course#;     --240, 314
  --                                              DBMS_OUTPUT.PUT_LINE('dept: '||dept3||', course#: '||course3);
                        showmessage := showmessage || dept3 || course3 || '|';
                                        end loop;
                                end loop;
                end loop;

exception
        when course#_invalid then
                --showmessage := concat(concat(concat(p_dept_code,'|'), p_course#), ' does not exist.');
                --dbms_output.put_line(p_dept_code||'|'||p_course#||' does not exist.');
                showmessage := p_dept_code||'|'||p_course#||' does not exist.';
end;

end procedure_try;
/     
show errors