---
layout: post
title: "Android Architecture Components 入门（一）—— Android Room Library 简单使用"
date: 2017-08-03 23:47:32 +0800
comments: true
categories: Android
---

Google 在今年的 IO 大会重点介绍了它们最新推出的 [Android Architecture Components](https://developer.android.com/topic/libraries/architecture/index.html)，其中最重要的一个就是 [Room](https://developer.android.com/topic/libraries/architecture/room.html)。在 Ormlite、GreenDao，甚至 Realm 大行其道的今天，Google 自己也总算造了一口锅自己背上了（只求 Google 日后不要轻易弃坑）。

这篇文章没有太多深奥的源码分析，因为我下午看完官方文档之后，还是觉得有点复杂，不利于初学者学习如何使用，所以打算写一篇文章来帮助大家入门。

Room 的一些特点
=====
1. **编译时 sql 语句检查**。相信大家都有过 app 跑起来，执行到 db 语句的时候 crash，检查之后发现原来是 sql 语句少了一个 `)` 或者其它符号之类的经历。Room 会在编译阶段检查你的 DAO 中的 sql 语句，如果写错了（包括 sql 语法错误跟表名、字段名等等错误），会直接编译失败并提醒你哪里不对。
2. **sql 查询直接关联到 Java 对象**。这个应该不用详细解释了，虽然很多第三方 db 库早已经实现。
3. **耗时操作主动要求异步处理**。这一点还是挺值得注意的，Room 会在执行 db 操作时判断是不是在 UI 线程，比如当你需要插入一条记录到数据库时，Room 会让你放到异步线程去做，否则会直接 crash 掉 app 来告诉你不这样做容易阻塞 UI 线程。虽说死相难看了点（个人觉得打个警告不就完了么?），但对于开发者开发出高质量的应用还是有帮助的。
4. **基于注解编译时自动生成代码**。这个应该算是 Room 工作原理的核心所在了，你要写的代码之所以这么少，说白了还不是因为 Google 给你写好了很多？希望以后有时间能写一篇源码分析出来，那个时候再讲吧。
5. **API 设计符合 Sql 标准**。方便扩展进行各种 db 操作。


Room 的三大组件
=====
* Entity。实体，说白了就是我们最常见的一个对象
* Database。数据库，Room 提供了一个非常方便的静态方法来供我们创建数据库
* DAO。Data Access Object，把你 Entity 所有的 CRUD 业务代码封装在这里就好

<!-- more -->

开始使用
===
Room 的用法，说白了就是创建上面的三大组件，写完了，剩下的交给 Google 就好。

* 创建一个实体类 `UserEntity.java`

```Java
@Entity(tableName = "user")
public class UserEntity {

    @PrimaryKey(autoGenerate = true)
    private int _id;

    private String name;
    private String age;

    public int get_id() {
        return _id;
    }

    public void set_id(int _id) {
        this._id = _id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getAge() {
        return age;
    }

    public void setAge(String age) {
        this.age = age;
    }

    public UserEntity(String name, String age) {
        this.name = name;
        this.age = age;
    }
}
```
*划重点：*

1. 顶部使用 `@Entity(tableName = "user")` 声明这是一个实体类。其中，`tableName` 如果不写，那么默认类名就是表名。因为我不想创建出来的表名叫 `UserEntity`，所以我声明了表名叫 `user`
2. 属性使用 `@PrimaryKey(autoGenerate = true)` 声明这是一个主键。其中，`autoGenerate = true` 代表自动生成，而且会随着数据增加自增长，可以理解成就是 `AUTOINCRESEMENT`

* 创建实体操作接口类 `UserEntityDao.java`

``` Java
@Dao
public interface UserEntityDao {

    @Query("select * FROM User")
    List<UserEntity> getUserList();

    @Query("select * FROM User WHERE name = :name")
    UserEntity getUserByName(String name);

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void addUser(UserEntity userEntity);

    @Delete()
    void deleteUser(UserEntity userEntity);

}
```
*划重点：*
1. 顶部使用 `@Dao` 声明这是 `DAO`，就是这么简单。
2. CRUD 操作全部使用注解声明，需要具体 sql 语句的，直接在注解里书写就好。具体支持哪些操作可以去 `android.arch.persistence.room` 包下面查看，我这边就随便写了几个。**注意，Room会在编译时检查你的 sql 语句，如果有语法错误，或者表名、字段名错误，都会直接编译报错让你修改，避免运行时出现 crash。**
3. 你问我这些接口的实现在哪？答案是：Google 会帮你搞定。是的，你只需要写这些就可以了。

* 创建数据库抽象类 `AppDatabase.java`

``` Java
@Database(entities = {UserEntity.class}, version = 2, exportSchema = false)
public abstract class AppDatabase extends RoomDatabase {

    private static AppDatabase sInstance;

    public static AppDatabase getDatabase(Context context) {
        if (sInstance == null) {
            sInstance = Room.databaseBuilder(context.getApplicationContext(), AppDatabase.class,
                    "user.db").build();
        }
        return sInstance;
    }

    public static void onDestroy() {
        sInstance = null;
    }

    public abstract UserEntityDao getUserEntityDao();

}
```

*划重点：*
1. 顶部使用 `@Database` 声明这是一个数据库类，其中 `entities`里面声明你的数据库里究竟包含了哪几个实体；`version` 就不用我说了吧，写过 `SqliteOpenHelper` 的肯定不陌生了；第三个属性 `exportSchema` 比较有意思，Google 建议是传 true，这样可以把 Scheme 导出到一个文件夹里面，Google 还建议你把这个文件上传到 VCS，具体的可以直接点进去看注释。
2. 这个类封装成单例，在任何地方需要执行数据库操作的时候，可以直接获得来使用，Room 提供了一个静态的方法，用来在默认的构造方法里创建了一个数据库，我在这里起的名称是 `user.db`。
3. 把所有 Entity 的 DAO 接口类全部声明成 abstract 的到这里来。
4. Google 会在编译时自动帮我们生成这些抽象类和方法的实现，代码在 `app/build/generated/source/apt/debug`

测试调用
=====

以增加一条数据为例：

```Java
UserEntity userEntity = new UserEntity("NAME, "AGE");    AppDatabase.getDatabase(getApplicationContext()).getUserEntityDao().addUser(userEntity);
```
上面的语句需要放到异步线程去调用，否则 Room 会直接 crash 掉你的 app 告诉你不这样做容易阻塞 UI 线程。虽然粗暴了一些，但想想也是合理的。再回到这段代码，会发现 Room 在实际场景中的用法非常简单，就是在任何你想操作数据库的地方，先拿到 database 对象，然后再拿到 `DAO` 对象，接着调用 `DAO` 里面定义的方法即可。而这些方法的具体实现，我们只需要写少量的 sql 语句，剩下的全部根据注解在编译时自动生成了，Simple and easy。


总结
===
以上就是对 Room 库使用方法的一个简单介绍，如果你看官方文档一头雾水的话，不如先从这个小例子起步，再对照回官方文档去深挖。其实 Room 的用法以及功能远不止这些，通过与 `ViewModel` 还有 `LiveData` 结合，可以轻松实现 db 以及对象的 observable，做到在 UI 的声明周期内，只要 db 数据变化，可以主动更新到 UI，不用再写繁琐的 `ContentProvider` 与 `ContentObserver`。而接下来有时间我也会继续学习 Android Architecture Components，争取把这个系列文章继续写下去。

