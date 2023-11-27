import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String path = await getDatabasesPath(); // 데이터베이스가 생성될 임의의 위치
  String myDB = 'doggie_database.db';
  String tableName = 'dogs';
  path = join(path, myDB);

  final database = openDatabase(
    path,
    version: 1,
    onCreate: (db, version) {
      return db.execute(
          'create table $tableName(id integer primary key, name text, age integer)');
    },
  );

  Future<void> insertDog(Dog dog) async {
    final db = await database; //왜 await일까?
    await db.insert('dogs', dog.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace); //동일데이터가 있으면 대체한다
  }

  Future<List<Dog>> getAllDogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('dogs'); //dogs 테이블로부터 모든 자료는 맵형태로 리스트에 담겨 온다.
    return List.generate(
        maps.length,
        (i) => Dog(
              id: maps[i]['id']
                  as int, //통신등으로 넘어오는 자료는 문자열형태가 많다. 그래서 원하는 타입으로 변환시켜야 된다.
              name: maps[i]['name'] as String,
              age: maps[i]['age'] as int,
            )).toList();
  }

  Future<void> updateDog(Dog dog) async {
    final db = await database;
    await db.update(
      'dogs', dog.toMap(),
      where: 'id = ?',
      whereArgs: [dog.id], // 리스트 안의 자료가 ?에 해당한다.
      //즉, 동일 아이디를 찾아서, 나머지 내용을 지금 내용으로 바꾼다.
    );
  }

  Future<void> deleteDog(int id) async {
    final db = await database;
    await db.delete(
      'dogs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //! 실제 잘 작동하는 지 점검
  var fido = Dog(id: 1, name: 'Fido', age: 35);
  var juju = Dog(id: 2, name: 'Juju', age: 20);
  await insertDog(fido);
  await insertDog(juju);
  print(await getAllDogs());

  fido = Dog(id: fido.id, name: fido.name, age: fido.age + 7);
  await updateDog(fido);
  print(await getAllDogs());

  await deleteDog(fido.id);
  print(await getAllDogs());
}

class Dog {
  final int id;
  final String name;
  final int age;
  Dog({
    required this.id,
    required this.name,
    required this.age,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
    };
  }

  @override
  String toString() {
    return 'Dog(id: $id, name:$name, age:$age)';
  }
}
