import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  Stream? userStream;
  Stream? userAgeStream;
  Stream? userInterestStream;
  TabController? tabController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    asyncMethod();
  }

  asyncMethod() async {
    await sub_async();
  }

  sub_async() async {
    setState(() {
      userStream = FirebaseFirestore.instance.collection('users').snapshots();
      userAgeStream = FirebaseFirestore.instance.collection('users').orderBy('age').snapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Demo'),
          bottom: const TabBar(
            tabs: [
              Tab(child: Text('All', style: TextStyle(color: Colors.black),),),
              Tab(child: Text('Age', style: TextStyle(color: Colors.black),),),
              Tab(child: Text('Interests', style: TextStyle(color: Colors.black),),),
            ]
          ),
        ),
        body: TabBarView(
          controller: tabController,
          children: [
            showAllUsers(),
            showUsersByAge(),
            const Icon(Icons.directions_boat),
          ],
        )
      ),
    );
  }

  showAllUsers() {
    return StreamBuilder(
      stream: userStream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        else {
          return ListView.builder(
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(top: 3, bottom: 3),
                  child: Card(
                    elevation: 6.0,
                    child: Column(
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                                child: Image(
                                  image: AssetImage('images/random.jpg'),
                                )
                            ),
                            subtitle: Text('Age: ${snapshot.data.docs[index].data()['age']}'),
                            title: Text(snapshot.data.docs[index].data()['name']),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Row(
                              children: [
                                const Text('Interests: '),
                                Row(
                                  children: snapshot.data.docs[index].data()['interests'].map<Widget>((item) => Text(item + ' | ')).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 7)
                        ]
                    ),
                  ),
                );
              }
          );
        }
      }
    );
  }

  showUsersByAge() {
    return StreamBuilder(
      stream: userAgeStream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        else {
          return ListView.builder(
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(top: 3, bottom: 3),
                  child: Card(
                    elevation: 6.0,
                    child: Column(
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                                child: Image(
                                  image: AssetImage('images/random.jpg'),
                                )
                            ),
                            subtitle: Text('Age: ${snapshot.data.docs[index].data()['age']}'),
                            title: Text(snapshot.data.docs[index].data()['name']),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Row(
                              children: [
                                const Text('Interests: '),
                                Row(
                                  children: snapshot.data.docs[index].data()['interests'].map<Widget>((item) => Text(item + ' | ')).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 7)
                        ]
                    ),
                  ),
                );
              }
          );
        }
      }
    );
  }
}
