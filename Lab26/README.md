#  Vagrant-стенд c LDAP на базе FreeIPA

#### Домашнее задание: 

1) Установить FreeIPA
2) Написать Ansible-playbook для конфигурации клиента


#### Решение:  

После запускамVagrantfile - будет  создано 3 виртуальных машины, подлюченные к единой сети: сервер LDAP и два клиентских хоста. 

На сервере LDAP устанавливается и настраивается сервер FreeIPA, на хостах - клиентские части. Управление участниками LDAP может производится из консоли непосредственно на сервере или с использованием веб-интерфейса.

Также были созданы 2 пользователя - User1 и User2, которым были предоставлены различные уровни доступа.

На сервере FreeIPA просматриваем записи пользователей:
```sh
[root@clientipa ~]# kinit admin
Password for admin@ipa.local:

[root@clientipa ~]# klist
Ticket cache: KEYRING:persistent:0:0
Default principal: admin@IPA.TEST
Valid starting       Expires              Service principal
11.07.2022 19:17:32  12.07.2022 19:17:23  krbtgt/IPA.TEST@IPA.TEST
```

```sh
[root@clientipa ~]# ipa user-find --all
---------------
3 users matched
---------------
  dn: uid=admin,cn=users,cn=accounts,dc=ipa,dc=test
  User login: admin
  Last name: Administrator
  Full name: Administrator
  Home directory: /home/admin
  GECOS: Administrator
  Login shell: /bin/bash
  Principal alias: admin@IPA.TEST
  User password expiration: 20221009160847Z
  UID: 227800000
  GID: 227800000
  Account disabled: False
  Preserved user: False
  Member of groups: admins, trust admins
  ipauniqueid: 2ba85bc6-0133-11ed-8fb3-5254004d77d3
  krbextradata: AAIPS8xicm9vdC9hZG1pbkBJUEEuVEVTVAA=
  krblastpwdchange: 20220711160847Z
  objectclass: top, person, posixaccount, krbprincipalaux, krbticketpolicyaux, inetuser, ipaobject, ipasshuser, ipaSshGroupOfPubKeys

  dn: uid=user1,cn=users,cn=accounts,dc=ipa,dc=test
  User login: user1
  First name: user1
  Last name: ivanov
  Full name: user1 ivanov
  Display name: user1 ivanov
  Initials: pi
  Home directory: /home/user1
  GECOS: user1 ivanov
  Login shell: /bin/sh
  Principal name: user1@IPA.TEST
  Principal alias: user1@IPA.TEST
  User password expiration: 20220711160955Z
  Email address: user1@ipa.test
  UID: 227800001
  GID: 227800001
  Account disabled: False
  Preserved user: False
  Member of groups: ipausers, manager
  ipauniqueid: e818f07c-0133-11ed-b04b-5254004d77d3
  krbextradata: AAJTS8xicm9vdC9hZG1pbkBJUEEuVEVTVAA=
  krblastpwdchange: 20220711160955Z
  mepmanagedentry: cn=user1,cn=groups,cn=accounts,dc=ipa,dc=test
  objectclass: top, person, organizationalperson, inetorgperson, inetuser, posixaccount, krbprincipalaux, krbticketpolicyaux, ipaobject, ipasshuser, ipaSshGroupOfPubKeys, mepOriginEntry

  dn: uid=user2,cn=users,cn=accounts,dc=ipa,dc=test
  User login: user2
  First name: user2
  Last name: sidorov
  Full name: user2 sidorov
  Display name: user2 sidorov
  Initials: vs
  Home directory: /home/user2
  GECOS: user2 sidorov
  Login shell: /bin/sh
  Principal name: user2@IPA.TEST
  Principal alias: user2@IPA.TEST
  User password expiration: 20220711160956Z
  Email address: user2@ipa.test
  UID: 227800003
  GID: 227800003
  Account disabled: False
  Preserved user: False
  Member of groups: ipausers, manager
  ipauniqueid: e8a18b08-0133-11ed-8671-5254004d77d3
  krbextradata: AAJUS8xicm9vdC9hZG1pbkBJUEEuVEVTVAA=
  krblastpwdchange: 20220711160956Z
  mepmanagedentry: cn=user2,cn=groups,cn=accounts,dc=ipa,dc=test
  objectclass: top, person, organizationalperson, inetorgperson, inetuser, posixaccount, krbprincipalaux, krbticketpolicyaux, ipaobject, ipasshuser, ipaSshGroupOfPubKeys, mepOriginEntry
----------------------------
Number of entries returned 3
----------------------------
```

```sh
[root@clientipa ~]# ipa group-find --all
----------------
5 groups matched
----------------
  dn: cn=admins,cn=groups,cn=accounts,dc=ipa,dc=test
  Group name: admins
  Description: Account administrators group
  GID: 227800000
  Member users: admin
  ipauniqueid: 2baa79c4-0133-11ed-910b-5254004d77d3
  objectclass: top, groupofnames, posixgroup, ipausergroup, ipaobject, nestedGroup

  dn: cn=editors,cn=groups,cn=accounts,dc=ipa,dc=test
  Group name: editors
  Description: Limited admins who can edit other users
  GID: 227800002
  ipauniqueid: 2babd7ce-0133-11ed-ad87-5254004d77d3
  objectclass: top, groupofnames, posixgroup, ipausergroup, ipaobject, nestedGroup

  dn: cn=ipausers,cn=groups,cn=accounts,dc=ipa,dc=test
  Group name: ipausers
  Description: Default group for all users
  Member users: user1, user2
  ipauniqueid: 2baba5ec-0133-11ed-9e73-5254004d77d3
  objectclass: top, groupofnames, nestedgroup, ipausergroup, ipaobject

  dn: cn=manager,cn=groups,cn=accounts,dc=ipa,dc=test
  Group name: manager
  GID: 227800004
  Member users: user2, user1
  ipauniqueid: e9579fce-0133-11ed-9d66-5254004d77d3
  objectclass: top, groupofnames, nestedgroup, ipausergroup, ipaobject, posixgroup

  dn: cn=trust admins,cn=groups,cn=accounts,dc=ipa,dc=test
  Group name: trust admins
  Description: Trusts administrators group
  Member users: admin
  ipauniqueid: ae6ca526-0133-11ed-9ec4-5254004d77d3
  objectclass: top, groupofnames, ipausergroup, nestedgroup, ipaobject
----------------------------
Number of entries returned 5
----------------------------
```

Для подключения к FreeIPA серверу с клиентских хостов используется Kerberos-инициализация, подключение к серверу по ssh и проверка текущей директории:

На хосте client1.ipa.local
```sh
[vagrant@client1 ~]$ kinit user1
Password for user1@ipa.local:
Password expired. You must change it now.
Enter new password:
Enter it again:
[vagrant@client1 ~]$ ssh user1@srv.ipa.local
[user1@client1 ~]$ pwd
/home/user1
[user1@client1 ~]$
```

На хосте client2.ipa.local
```sh
[vagrant@client2 ~]$ kinit user2
Password for user2@ipa.local:
Password expired. You must change it now.
Enter new password:
Enter it again:
[vagrant@client2 ~]$ ssh user2@srv.ipa.local
[user2@client2 ~]$ pwd
/home/user2
[user2@client2 ~]$
```