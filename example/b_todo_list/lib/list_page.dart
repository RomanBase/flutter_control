import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

import 'list_control.dart';

class TodoListPage extends SingleControlWidget<TodoListControl> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
        actions: <Widget>[
          IconButton(
            onPressed: control.clear,
            icon: Icon(Icons.delete_forever),
          ),
        ],
      ),
      body: ListBuilder<TodoItemModel>(
        control: control.list,
        builder: (context, value) {
          return ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, index) => ItemWidget(
              model: value[index],
              onEditPressed: (model) {
                showDialog(
                  context: context,
                  builder: (context) => ItemDialog(model: model),
                );
              },
            ),
          );
        },
        noData: (context) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('List is Empty'),
              SizedBox(
                height: 32.0,
              ),
              RaisedButton(
                onPressed: control.fillTestData,
                child: Text('fill with test data'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => ItemDialog(),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class ItemWidget extends StatelessWidget {
  final TodoItemModel model;
  final ValueCallback<TodoItemModel> onEditPressed;

  ItemWidget({
    this.model,
    this.onEditPressed,
  }) : super(key: ObjectKey(model));

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: model.toggle,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => onEditPressed(model),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                model.title,
              ),
            ),
          ),
          ControlBuilder(
            control: model,
            builder: (context, value) => Checkbox(
              value: model.isDone,
              onChanged: (checked) => model.isDone = checked,
            ),
          )
        ],
      ),
    );
  }
}

class ItemDialog extends SingleControlWidget<ItemDialogControl> {
  ItemDialog({Key key, TodoItemModel model}) : super(key: key, args: model);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black45,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: () => control.title.setFocus(false),
              child: Container(
                margin: const EdgeInsets.all(32.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  color: Theme.of(context).canvasColor,
                ),
                child: Column(
                  children: <Widget>[
                    Text(control.editMode ? 'Update item' : 'Add new item'),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16.0),
                      height: 1,
                      color: Colors.black12,
                    ),
                    InputFieldV1(
                      control: control.title,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      label: 'item name',
                      //TODO: submit from UI
                    ),
                    SizedBox(
                      height: 16.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        if (control.editMode)
                          RaisedButton(
                            onPressed: () {
                              if (control.remove()) {
                                Navigator.of(context).pop();
                              }
                            },
                            color: Colors.red,
                            child: Text('DELETE'),
                          ),
                        RaisedButton(
                          onPressed: () {
                            if (control.submit()) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(control.editMode ? 'UPDATE' : 'CREATE'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
