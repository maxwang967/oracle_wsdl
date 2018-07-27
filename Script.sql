--（1）以下在sysdba用户下进行
--调整JAVA POOL大小
alter system set SHARED_POOL_SIZE=132M scope=both; 
alter system set JAVA_POOL_SIZE=80M scope=both;
--授权给新创建的用户（假设用户名为SCOTT）
--注意：此处填写的用户名必须为英文大写字母
grant CREATE PUBLIC SYNONYM to SCOTT;
call dbms_java.grant_permission('SCOTT','SYS:java.lang.RuntimePermission', 'shutdownHooks', '' );
call dbms_java.grant_permission('SCOTT','SYS:java.util.logging.LoggingPermission', 'control', '' );
call dbms_java.grant_permission('SCOTT','SYS:java.util.PropertyPermission','http.proxySet','write');
call dbms_java.grant_permission('SCOTT','SYS:java.util.PropertyPermission','http.proxyHost', 'write');
call dbms_java.grant_permission('SCOTT','SYS:java.util.PropertyPermission','http.proxyPort', 'write');
call dbms_java.grant_permission('SCOTT','SYS:java.lang.RuntimePermission','getClassLoader','');
call dbms_java.grant_permission('SCOTT','SYS:java.net.SocketPermission','*','connect,resolve');
call dbms_java.grant_permission('SCOTT','SYS:java.util.PropertyPermission','*','read,write');
call dbms_java.grant_permission('SCOTT','SYS:java.lang.RuntimePermission','setFactory','');
call dbms_java.grant_permission('SCOTT','SYS:java.lang.RuntimePermission', 'accessClassInPackage.sun.util.calendar','');

--（2）以下在终端oracle所属用户下进行，目录需要定位到$ORACLE_HOME/sqlj/lib下
--导入编译好的jar包，其中包括Main类、wsdl相关类以及各类依赖包，需要注意在jdk1_5_17下进行编译，oracle驱动使用5_g版本，日志将保存到loadjava.txt下
loadjava -u scott/tiger -r -v -f -s -grant public -genmissing rpcinvoke15.jar >& loadjava.txt
--如果loadjava命令不可用，请执行. oraenv命令（点后有空格）并输入实例名称进行初始化
--如果日志中除了oracle驱动以外全部类导入没有报错，则说明导包成功；否则请检查所导入jar包是否为jdk1_5编译且是否正确授权


--（3）以下在新创建的用户下进行，需要给予至少等同于scott用户的权限
--编译Java Source，调用导入的Main类的main方法，传入sfzh和token
create or replace and compile java source named InvokeIDRPC as package wms;
import com.edward.wsdldemo.Main;
public class InvokeIDRPC{
       public static void invokeIDRPC(String sfzh, String token)
       {
              Main.main(sfzh,token);
       }
}

--创建存储过程，调用编译好的Java Source
create or replace procedure InvokeIDRPC_P( sfzh in VARCHAR2,token in VARCHAR2) as language java name 'wms.InvokeIDRPC.invokeIDRPC(java.lang.String,java.lang.String)';

--创建触发器，在插入操作前触发，执行存储过程
create or replace trigger InvokeIDRPC_T
before insert
on request_data_new 
for each row
begin
    InvokeIDRPC_P(:new.SFZH,:new.TOKEN);
end;

--测试存储过程语句
begin
  -- Call the procedure
  InvokeIDRPC_P('231084199706043515','3333333');
end;
