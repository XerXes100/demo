import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multiselect/multiselect.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {

  Stream? userStream;
  Stream? userNameStream;
  Stream? userAgeStream;
  Stream? interestStream;
  TabController? tabController;
  // int _currentIndex = 0;
  String? _uploadedFileURL;

  TextEditingController? nameController = TextEditingController();
  TextEditingController? ageController = TextEditingController();

  PickedFile? _image;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    asyncMethod();
    // tabController = TabController(vsync: this, length: 4);
    // tabController!.addListener(_handleTabSelection);
  }

  // _handleTabSelection() {
  //   setState(() {
  //     _currentIndex = tabController!.index;
  //   });
  //   if (_currentIndex == 0) {
  //     setState(() {
  //       userStream = FirebaseFirestore.instance.collection('users').snapshots();
  //     });
  //   }
  // }

  asyncMethod() async {
    await sub_async();
  }

  sub_async() async {
    setState(() {
      userStream = FirebaseFirestore.instance.collection('users').snapshots();
      userAgeStream = FirebaseFirestore.instance.collection('users').orderBy('age').snapshots();
      userNameStream = FirebaseFirestore.instance.collection('users').orderBy('name').snapshots();
      interestStream = FirebaseFirestore.instance.collection('interests').snapshots();
    });
  }

  List<String> selected = [];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Demo'),
          bottom: const TabBar(
            tabs: [
              Tab(child: Text('All')),
              Tab(child: Text('Name')),
              Tab(child: Text('Age')),
              Tab(child: Text('Interests'))
            ]
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.add_box_outlined,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 90.0,
                            vertical: 15.0,
                          ),
                          child: GestureDetector(
                            onTap: chooseFileFromGallery,
                            child: Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                                color: Color(0xffaeaeae)
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("Choose your profile picture"),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.0,
                            vertical: 8.0,
                          ),
                          child: TextFormField(
                            validator: (val) => (val ?? '').length < 3
                                ? "Name is too short."
                                : '',
                            controller: nameController,
                            decoration: const InputDecoration(
                              hintText: 'Enter your name...'
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.0,
                            vertical: 8.0,
                          ),
                          child: TextFormField(
                            validator: (val) => (val ?? '').length < 3
                                ? "Name is too short."
                                : '',
                            controller: ageController,
                            decoration: const InputDecoration(
                                hintText: 'Enter your age...'
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 10.0,
                          ),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: DropDownMultiSelect(
                                  onChanged: (List<String> x) {
                                    setState(() {
                                      selected = x;
                                    });
                                  },
                                  options: [
                                    'Politics',
                                    'Entertainment',
                                    'History',
                                    "Sports",
                                    'Health'
                                  ],
                                  selectedValues: selected,
                                  whenEmpty: 'Select interests',
                                ),
                              ),
                            ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 90.0,
                            vertical: 15.0,
                          ),
                          child: GestureDetector(
                            onTap: createProfile,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xffaeaeae),
                                borderRadius: BorderRadius.all(Radius.circular(20))
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
                                child: Text("Create"),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                );
              },
            )
          ]
        ),
        body: TabBarView(
          controller: tabController,
          children: [
            showAllUsers(),
            showUsersByName(),
            showUsersByAge(),
            showInterests(),
          ],
        )
      ),
    );
  }

  Future chooseFileFromGallery() async {
    ImagePicker imagePicker = ImagePicker();
    await imagePicker.getImage(source: ImageSource.gallery).then((image) async {
      setState(() {
        _image = image;
        print("Image path ${_image!.path}");
      });
    });
  }

  uploadImageGetURL() async {
    File? _imageFile = File(_image!.path);

    firebase_storage.Reference storageReference =
    firebase_storage.FirebaseStorage.instance.ref(path.basename(_imageFile.path));

    firebase_storage.UploadTask uploadTask =
      storageReference.putFile(_imageFile);
    await uploadTask;
    await storageReference.getDownloadURL().then((fileURL) {
      setState(() {
        _uploadedFileURL = fileURL;
      });
    });
  }

  createProfile() async {
    await uploadImageGetURL();
    Map<String, dynamic> temp_map = {
      'name': nameController!.text,
      'age': ageController!.text,
      'interests': selected,
      'photoURL': _uploadedFileURL
    };
    await FirebaseFirestore.instance.collection('users').add(temp_map);
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 4.0,
                    child: Column(
                      children: [
                        ///https://firebasestorage.googleapis.com/v0/b/fir-77522.appspot.com/o/default.jpeg?alt=media&token=01007874-9b4d-4ece-a106-5faa6f9022fa
                        ListTile(
                          // leading: const CircleAvatar(
                          //     // child: Image(
                          //     //   image: AssetImage('images/random.jpg'),
                          //     // )
                          //   child: Image.network('https://firebasestorage.googleapis.com/v0/b/fir-77522.appspot.com/o/random.jpg?alt=media&token=2c0d5851-9bca-4a68-8de2-ccbfa7f9a0c6')
                          // ),
                          leading: snapshot.data.docs[index].data()['photoURL'] != null
                              ? Image.network(snapshot.data.docs[index].data()['photoURL'], width: 50, height: 50,)
                              : Image.network('https://firebasestorage.googleapis.com/v0/b/fir-77522.appspot.com/o/default.jpeg?alt=media&token=01007874-9b4d-4ece-a106-5faa6f9022fa', width: 50, height: 50,),
                          subtitle: Text('Age: ${snapshot.data.docs[index].data()['age']}'),
                          title: Text(snapshot.data.docs[index].data()['name']),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Row(
                            children: [
                              const Text('Interests: '),
                              Row(
                                children: snapshot.data.docs[index].data()['interests'].map<Widget>((item) => Row(
                                  children: [
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF2F2F2),
                                        borderRadius: BorderRadius.all(Radius.circular(5))
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 5.0),
                                        child: Text(item),
                                      )
                                    ),
                                    const Text(' | ')
                                  ],
                                )).toList(),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 4.0,
                    child: Column(
                        children: [
                          ListTile(
                            leading: snapshot.data.docs[index].data()['photoURL'] != null
                                ? Image.network(snapshot.data.docs[index].data()['photoURL'], width: 50, height: 50,)
                                : Image.network('https://firebasestorage.googleapis.com/v0/b/fir-77522.appspot.com/o/default.jpeg?alt=media&token=01007874-9b4d-4ece-a106-5faa6f9022fa', width: 50, height: 50,),
                            subtitle: Text('Age: ${snapshot.data.docs[index].data()['age']}'),
                            title: Text(snapshot.data.docs[index].data()['name']),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Row(
                              children: [
                                const Text('Interests: '),
                                Row(
                                  children: snapshot.data.docs[index].data()['interests'].map<Widget>((item) => Row(
                                    children: [
                                      Container(
                                          decoration: const BoxDecoration(
                                              color: Color(0xFFF2F2F2),
                                              borderRadius: BorderRadius.all(Radius.circular(5))
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 5.0),
                                            child: Text(item),
                                          )
                                      ),
                                      const Text(' | ')
                                    ],
                                  )).toList(),
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

  showUsersByName() {
    return StreamBuilder(
      stream: userNameStream,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 4.0,
                  child: Column(
                    children: [
                      ListTile(
                      leading: snapshot.data.docs[index].data()['photoURL'] != null
                          ? Image.network(snapshot.data.docs[index].data()['photoURL'], width: 50, height: 50,)
                          : Image.network('https://firebasestorage.googleapis.com/v0/b/fir-77522.appspot.com/o/default.jpeg?alt=media&token=01007874-9b4d-4ece-a106-5faa6f9022fa', width: 50, height: 50,),
                        subtitle: Text('Age: ${snapshot.data.docs[index].data()['age']}'),
                        title: Text(snapshot.data.docs[index].data()['name']),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Row(
                          children: [
                            const Text('Interests: '),
                            Row(
                              children: snapshot.data.docs[index].data()['interests'].map<Widget>((item) => Row(
                                children: [
                                  Container(
                                      decoration: const BoxDecoration(
                                          color: Color(0xFFF2F2F2),
                                          borderRadius: BorderRadius.all(Radius.circular(5))
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 5.0),
                                        child: Text(item),
                                      )
                                  ),
                                  const Text(' | ')
                                ],
                              )).toList(),
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

  showInterests() {
    return StreamBuilder(
        stream: interestStream,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      elevation: 4.0,
                      child: Column(
                        children: [
                          ListTile(
                            // subtitle: Text('Age: ${snapshot.data.docs[index].data()['age']}'),
                            title: Text(snapshot.data.docs[index].data()['name']),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                builder: (context) {
                                  return StreamBuilder(
                                      stream: FirebaseFirestore.instance.collection('users')
                                          .where('interests', arrayContains: snapshot.data.docs[index].data()['name'])
                                          .snapshots(),
                                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        else {
                                          if (snapshot.data.docs.length == 0) {
                                            return const Center(
                                              child: Text('No users yet.')
                                            );
                                          }
                                          return ListView.builder(
                                              itemCount: snapshot.data.docs.length,
                                              itemBuilder: (context, index) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 3, bottom: 3),
                                                  child: Card(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10.0),
                                                    ),
                                                    elevation: 4.0,
                                                    child: Column(
                                                      children: [
                                                        ListTile(
                                                          leading: snapshot.data.docs[index].data()['photoURL'] != null
                                                            ? Image.network(snapshot.data.docs[index].data()['photoURL'], width: 50, height: 50,)
                                                            : Image.network('https://firebasestorage.googleapis.com/v0/b/fir-77522.appspot.com/o/default.jpeg?alt=media&token=01007874-9b4d-4ece-a106-5faa6f9022fa', width: 50, height: 50,),
                                                          subtitle: Text('Age: ${snapshot.data.docs[index].data()['age']}'),
                                                          title: Text(snapshot.data.docs[index].data()['name']),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.only(left: 16.0),
                                                          child: Row(
                                                            children: [
                                                              const Text('Interests: '),
                                                              Row(
                                                                children: snapshot.data.docs[index].data()['interests'].map<Widget>((item) => Row(
                                                                  children: [
                                                                    Container(
                                                                        decoration: const BoxDecoration(
                                                                            color: Color(0xFFF2F2F2),
                                                                            borderRadius: BorderRadius.all(Radius.circular(5))
                                                                        ),
                                                                        child: Padding(
                                                                          padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 5.0),
                                                                          child: Text(item),
                                                                        )
                                                                    ),
                                                                    const Text(' | ')
                                                                  ],
                                                                )).toList(),
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
                              );
                            },
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
