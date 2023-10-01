import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
        print(response.body);
        return jsonDecode(response.body);
      } else {

        throw Exception('request failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('error: $e');
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
                return Center(child: Text('Error: ${snapshot.error}'));
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
                    child: Image.network(widget.blog['image_url'],fit: BoxFit.cover,),
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
      title: Text(id,overflow: TextOverflow.ellipsis,),
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
              child: Image.network(url,fit: BoxFit.fitWidth,),
            ),
            Text(title)
          ],
        ),
      ),
    ),
  );
}