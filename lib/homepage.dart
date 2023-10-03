import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
class DatabaseHelper {
  late Database _database;

  Future<void> initializeDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'your_database.db');

    _database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('CREATE TABLE IF NOT EXISTS blogs (title TEXT, image_url TEXT)');
        });
  }

  Future<void> insertBlog(Map<String, dynamic> blog) async {
    final Map<String, dynamic> blogData = {
      'title': blog['title'],
      'image_url': blog['image_url'],

    };

    await _database.insert('blogs', blogData,conflictAlgorithm: ConflictAlgorithm.replace);
  }


  Future<List<Map<String, dynamic>>> getBlogs() async {
    return await _database.query('blogs');
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initializeData();
  }
  Future<void> _initializeData() async {
    await _databaseHelper.initializeDatabase();
    final offlineData = await _databaseHelper.getBlogs();

    if (offlineData.isEmpty) {
      final onlineData = await fetchBlogs();
      onlineData['blogs'].forEach((blog) {
        _databaseHelper.insertBlog(blog);
      });
    }

    setState(() {});
  }
  Map<String,dynamic> list = {};
  Future<Map<String, dynamic>> fetchBlogs() async {
    final String url = 'https://intent-kit-16.hasura.app/api/rest/blogs';
    final String adminSecret = '32qR4KmXOIpsGPQKMqEJHGJS27G5s7HdSKO3gdtQd2kv5e852SiYwWNfxkZOBuQ6';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'x-hasura-admin-secret': adminSecret,
      });

      if (response.statusCode == 200) {
        final onlineData = jsonDecode(response.body);

        onlineData['blogs'].forEach((blog) {
          _databaseHelper.insertBlog(blog);
        });
        return onlineData;
      } else {
        final offlineData = await _databaseHelper.getBlogs();
        if (offlineData.isNotEmpty) {
          return {'blogs': offlineData};
        } else {
          throw Exception('Network request failed, and no offline data available.');
        }
      }
    } catch (e) {
      final offlineData = await _databaseHelper.getBlogs();
      if (offlineData.isNotEmpty) {
        return {'blogs': offlineData};
      } else {
        throw Exception('Error: $e, and no offline data available.');
      }
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blogs and Articles',
          style: TextStyle(
            color: Colors.white,

          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
            child: FutureBuilder(
              future: fetchBlogs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  print(snapshot.error);
                  return Center(child: Text('${snapshot.error}'));
                } else if (!snapshot.hasData || (snapshot.data?['blogs'] as List<dynamic>?) == null) {
                  return Center(child: Text('No data available.'));
                } else {
                  final blogList = snapshot.data?['blogs'] as List<dynamic>;
                  return ListView.separated(
                    scrollDirection: Axis.vertical,
                    separatorBuilder: (context, index) => SizedBox(height: 16.0),
                    shrinkWrap: true,
                    itemCount: blogList.length,
                    physics: AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final blog = blogList[index];
                      return entry(blog: blog);
                    },
                  );
                }
              },
            )

        ),
      ),
    );
  }
}

class entry extends StatefulWidget {
  final dynamic blog;
  entry({required this.blog});
  @override
  State<entry> createState() => _entryState();
}

class _entryState extends State<entry> {
  bool bookmark = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context)=> page(widget.blog['id'],widget.blog['title'],widget.blog['image_url'])));
      },
      child: Container(
          height: 400,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.grey.shade800
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.blog['image_url'],
                      placeholder: (context, url) => Container(),
                      errorWidget: (context, url, error) => Container(),
                      fit: BoxFit.cover,
                      cacheManager: DefaultCacheManager(),

                    ),
                  ),
                  GestureDetector(
                    onTap: (){

                      setState(() {
                        bookmark = !bookmark;
                      });
                    },
                    child: bookmark? Icon(
                        Icons.bookmark
                    ) :Icon(
                        Icons.bookmark_add
                    ),
                  )
                ],
              ),
              SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(widget.blog['title'],textAlign: TextAlign.left,style: TextStyle(fontSize: 18),overflow: TextOverflow.ellipsis,),
              ),

            ],
          )
      ),
    );
  }
}
page(id, title, url) {
  return Scaffold(
    appBar: AppBar(

    ),
    body: Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: double.infinity,
              height: 400,
              child: CachedNetworkImage(
                imageUrl: url,
                placeholder: (context, url) => Container(),
                errorWidget: (context, url, error) => Container(),
                fit: BoxFit.cover,
                cacheManager: DefaultCacheManager(),

              ),
            ),
            Text(title)
          ],
        ),
      ),
    ),
  );
}