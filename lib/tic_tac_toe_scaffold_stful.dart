library tic_tac_toe_scaffold;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'socket_helper.dart';
//цвета используемые в приложении
class _MyColors {
  static const BORDER_COLOR = Color.fromRGBO(119, 118, 118, 1);
  static const DISABLED_BORDER_COLOR = Color.fromRGBO(208, 208, 208, 1);
  static const BACKGROUND_COLOR = Color.fromRGBO(239, 239, 239, 1);
  static const DISABLED_BACKGROUND_COLOR = Color.fromRGBO(238, 238, 238, 1);
  static const DISABLED_TEXT_COLOR = Color.fromRGBO(171, 171, 171, 1);
  static const TEXT_COLOR = Color.fromRGBO(0, 0, 0, 1);
}
//Вспомогательный класс для работы с объектом игрового поля
class _GameFieldHelper {
  //инициализация игрового объекта поля
  static Map<String, String> initGameField() {
    Map<String,String> resMap = Map();
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        resMap[createRiCjKey(i, j)] = "";
      }
    }
    return resMap;
  }
  //создание удобного ключа, который передается/получается через сокет
  static String createRiCjKey(int i, int j) {
    return 'r' + i.toString() + 'c' + j.toString();
  }
  //провера игры на окончание
  static bool gameIsOver(Map<String, String> gameField) {
    List<String> winCondition = ['XXX', 'OOO'];
    List<String> rows = [
      gameField[createRiCjKey(0, 0)] + gameField[createRiCjKey(0, 1)] + gameField[createRiCjKey(0, 2)], //row1
      gameField[createRiCjKey(1, 0)] + gameField[createRiCjKey(1, 1)] + gameField[createRiCjKey(1, 2)], //row2
      gameField[createRiCjKey(2, 0)] + gameField[createRiCjKey(2, 1)] + gameField[createRiCjKey(2, 2)], //row3

      gameField[createRiCjKey(0, 0)] + gameField[createRiCjKey(1, 0)] + gameField[createRiCjKey(2, 0)], //column1
      gameField[createRiCjKey(0, 1)] + gameField[createRiCjKey(1, 1)] + gameField[createRiCjKey(2, 1)], //column2
      gameField[createRiCjKey(0, 2)] + gameField[createRiCjKey(1, 2)] + gameField[createRiCjKey(2, 2)], //column3

      gameField[createRiCjKey(0, 0)] + gameField[createRiCjKey(1, 1)] + gameField[createRiCjKey(2, 2)], //main diagonal
      gameField[createRiCjKey(0, 2)] + gameField[createRiCjKey(1, 1)] + gameField[createRiCjKey(2, 0)] // secondary diagonal
    ];

    for (int i = 0; i < rows.length; i ++) {
      if (rows[i] == winCondition[0] || rows[i] == winCondition[1]) {
        return true;
      }
    }
    return false;
  }
}

class TicTacToeScaffold extends StatefulWidget {
  @override
  _TicTacToeScaffoldState createState() => _TicTacToeScaffoldState();
}

class _TicTacToeScaffoldState extends State<TicTacToeScaffold> {
  //url сокета
  static const String _SERVER_URL = 'https://tic-tac-toe-app2.herokuapp.com';
  //основные переменные отвечающие за изменение интерфейса
  SocketHelper _socketHelper;
  String _symbol;
  bool _buttonsDisabled = true;
  String _textState = 'Connecting...';
  bool _myTurn;
  Map<String,String> _gameField;

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    _gameField = _GameFieldHelper.initGameField();
    _socketHelper = SocketHelper(_SERVER_URL, {
      'game.begin': _gameBegin,
      'move.made': _moveMade,
      'opponent.left': _opponentLeft,
      'connect': _connected
    });
  }
  //ряд вспомогательных, изменяющих состояние, функций,которые привязываются к событиям сокета
  String _getText(int i, int j) {
    return _gameField[_GameFieldHelper.createRiCjKey(i, j)];
  }
  void _connected(_) {
    setState(() {
      _textState = 'Waiting for an opponent...';
    });
  }
  void _opponentLeft(_) {
    setState(() {
      _buttonsDisabled = true;
      _textState = 'Your opponent left';

    });
  }
  void _changeTurnProps() {
    if (_myTurn) {
      _textState = 'Your turn';
      _buttonsDisabled = false;
    }
    else {
      _textState = "Your opponent's turn";
      _buttonsDisabled = true;
    }
  }
  void _gameBegin(data) {
    setState(() {
      _symbol = data['symbol'];
      _myTurn = _symbol == 'X';
      _changeTurnProps();
    });

  }
  void _moveMade(data) {
    setState(() {
      _gameField[data['position']] = data['symbol'];
      _myTurn = _symbol != data['symbol'];
      if (!_GameFieldHelper.gameIsOver(_gameField)) {
        _changeTurnProps();
      }
      else {
        if (_myTurn) {
          _textState = 'You lost!';
        }
        else {
          _textState = 'You won!';
        }
        _buttonsDisabled = true;
      }
    });
  }
  void _makeMove(int i, int j) {
    _socketHelper.emitEvent('make.move',{
      'position': _GameFieldHelper.createRiCjKey(i, j),
      'symbol': _symbol
    });
    setState(() {
      _buttonsDisabled = true;
    });
  }
  //функция создания кнопки
  Widget _createButton(int i, int j) {
    return FlatButton(
        color: _MyColors.BACKGROUND_COLOR,
        textColor: _MyColors.TEXT_COLOR,
        disabledColor: _MyColors.DISABLED_BACKGROUND_COLOR,
        disabledTextColor: _MyColors.DISABLED_TEXT_COLOR,
        splashColor: _MyColors.BACKGROUND_COLOR,

        onPressed: _buttonsDisabled? null : () => {_makeMove(i,j)},
        child: Container(
          child: Center(
              child: Text(
                  _getText(i, j),
                  style: TextStyle(fontSize: 40.0)
              )
          ),
          width: 100.0,
          height: 100.0,
        )
    );
  }
  //функция создания массива строк для таблицы
  List<TableRow> _createTableRowArray() {
    List<TableRow> resTableRows = [];
    for (int i =0; i < 3; i++) {
      List<Widget> tableRowChildren = [];
      for (int j = 0; j < 3; j++) {
        tableRowChildren.add(Container(
          padding: EdgeInsets.all(5.0),
          child: Container(
            child: _createButton(i,j),
            decoration:  BoxDecoration(
              border: Border.all(
                  color: _buttonsDisabled? _MyColors.DISABLED_BORDER_COLOR: _MyColors.BORDER_COLOR
              ),
            ),
          )
        ));
      }
      resTableRows.add(TableRow(
          children: tableRowChildren
      ));
    }
    return resTableRows;
  }
  //функция создания таблицы
  Widget _buildTable() {
    return Container(
        child: ListView(
            padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
            children: <Widget> [
              Text(
                _textState,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                ),
              ),
              Table(
                children: _createTableRowArray(),
              )
            ]
        )
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('TicTacToe'),
        ),
        body: _buildTable()
    );
  }
}