import 'package:flutter/material.dart';

class CustomerPage extends StatefulWidget {
  CustomerPage({
    Key? key,
  }) : super(key: key);

  @override
  _CustomerPageState createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  List fooList = ['one', 'two', 'three', 'four', 'five'];
  List filteredList = [];
  @override
  void initState() {
    super.initState();
    filteredList = fooList;
  }

  void filter(String inputString) {
    filteredList =
        fooList.where((i) => i.toLowerCase().contains(inputString)).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "الزبائن",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search ',
              hintStyle: TextStyle(
                fontSize: 14,
              ),
            ),
            onChanged: (text) {
              text = text.toLowerCase();
              filter(text);
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (BuildContext context, int index) => ListTile(
                title: Text(filteredList[index]),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Display(
                        text: filteredList[index],
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

class Display extends StatelessWidget {
  final String? text;

  const Display({Key? key, this.text}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(text!),
      ),
    );
  }
}
