import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:plataform_channel_game/constants/colors.dart';
import 'package:plataform_channel_game/constants/styles.dart';
import 'package:plataform_channel_game/models/creator.dart';
import 'package:flutter/services.dart';
import 'package:plataform_channel_game/models/message.dart';

class GameWidget extends StatefulWidget {
  const GameWidget({Key? key}) : super(key: key);

  @override
  State<GameWidget> createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget> {

  static const platform = MethodChannel('game/exchange');

  Creator? creator;
  bool minhaVez = false;

  List<List<int>> cells = [
    [0, 0, 0],
    [0, 0, 0],
    [0, 0, 0]
  ];

  @override
  void initState(){
    super.initState();
    configurePubNub();
  }

  void configurePubNub(){
    platform.setMethodCallHandler((call) async {
      String action = call.method;
      String arguments = call.arguments.toString();
      List<String> parts = arguments.split("|");

      if(action == "sendAction"){
        ExchangeMessage message =
         ExchangeMessage(parts[0], int.parse(parts[1]), int.parse(parts[2]));

        if(message.user == (creator!.creator ? "p2" : "p1")){
          setState(() {
            minhaVez = true;
            cells[message.x][message.y] = 2;
          });
          checkWinner();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(700, 1400));

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: ScreenUtil().setWidth(550),
                      height: ScreenUtil().setHeight(550),
                      color: colorLightBlue1,
                    ),
                    Container(
                      width: ScreenUtil().setWidth(150),
                      height: ScreenUtil().setHeight(550),
                      color: colorMediumBlue2,
                    )
                  ],
                ),
                Container(
                  width: ScreenUtil().setWidth(700),
                  height: ScreenUtil().setHeight(850),
                  color: colorDarkBlue3,
                ),
              ],
            ),
            Container(
              height: ScreenUtil().setHeight(1400),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    creator == null ?
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildButton("Criar", true),
                          SizedBox(width: 10),
                          buildButton("Entrar", false),
                        ],
                      )
                    : InkWell(
                      child: Text(
                        minhaVez ? "Faça sua jogada" : "Aguarde sua vez",
                        style: textStyle36,
                      ),
                      onLongPress: (){
                        _sendMessage();
                      },
                    ),
                    GridView.count(
                      crossAxisCount: 3,
                      padding: const EdgeInsets.all(20),
                      shrinkWrap: true,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        getCell(0,0),
                        getCell(0,1),
                        getCell(0,2),
                        getCell(1,0),
                        getCell(1,1),
                        getCell(1,2),
                        getCell(2,0),
                        getCell(2,1),
                        getCell(2,2)
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildButton(String label, bool owner) => Container(
    width: ScreenUtil().setWidth(300),
    child: ElevatedButton(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          label,
          style: textStyle36,
        ),
      ),
      onPressed: () {
        createGame(owner);
      },
    )
  );

  Future createGame(bool owner) async {
    TextEditingController controller = TextEditingController();
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context){
        return AlertDialog(
          title: const Text("Qual o nome do jogo?"),
          content: TextField(controller: controller),
          actions: [
            ElevatedButton(
              child: const Text("Jogar"),
              onPressed: () {
                Navigator.of(context).pop();
                _sendAction('subscribe', {'channel': controller.text}).then((value){
                  setState(() {
                    creator = Creator(owner, controller.text);
                    minhaVez = owner;
                  });
                });
              },
            )
          ],
        );
      }
    );
  }

  Future<bool> _sendAction(String action, Map<String, dynamic> arguments) async {
    try{
      final bool result = await platform.invokeMethod(action, arguments);
      if(result){
       return true; 
      }
    }catch(e){}
    return false;
  }

  Widget getCell(int x, int y) => InkWell(
    child: Container(
      padding: const EdgeInsets.all(8),
      color: Colors.lightBlueAccent,
      child: Center(
        child: Text(
          cells[x][y] == 0 ? "" : cells[x][y] == 1 ? "X" : "O",
          style: textStyle75,
        ),
      ),
    ),
    onTap: () async {
      if(minhaVez == true && cells[x][y] == 0){
        _showSendingAction();
        _sendAction('sendAction', 
        {'tap': '${creator!.creator ? "p1" : "p2"}|$x$y'}).then((value){
          //Navigator.of(context).pop();
          setState(() {
            minhaVez = false;
            cells[x][y] = 1;
          });

          checkWinner();
        });
      }
    },
  );

  void _showSendingAction(){

  }

  void checkWinner(){
    bool youWin = false;
    bool enemyWin = false;

    //rows
    if (cells[0][0] == 1 && cells[0][1] == 1 && cells[0][2] == 1) {
      youWin = true;
    } else if (cells[0][0] == 2 && cells[0][1] == 2 && cells[0][2] == 2) {
      enemyWin = true;
    }

    if (cells[1][0] == 1 && cells[1][1] == 1 && cells[1][2] == 1) {
      youWin = true;
    } else if (cells[1][0] == 2 && cells[1][1] == 2 && cells[1][2] == 2) {
      enemyWin = true;
    }

    if (cells[2][0] == 1 && cells[2][1] == 1 && cells[2][2] == 1) {
      youWin = true;
    } else if (cells[2][0] == 2 && cells[2][1] == 2 && cells[2][2] == 2) {
      enemyWin = true;
    }

    //columns
    if (cells[0][0] == 1 && cells[1][0] == 1 && cells[2][0] == 1) {
      youWin = true;
    } else if (cells[0][0] == 2 && cells[1][0] == 2 && cells[2][0] == 2) {
      enemyWin = true;
    }

    if (cells[0][1] == 1 && cells[1][1] == 1 && cells[2][1] == 1) {
      youWin = true;
    } else if (cells[0][1] == 2 && cells[1][1] == 2 && cells[2][1] == 2) {
      enemyWin = true;
    }

    if (cells[0][2] == 1 && cells[1][2] == 1 && cells[2][2] == 1) {
      youWin = true;
    } else if (cells[0][2] == 2 && cells[1][2] == 2 && cells[2][2] == 2) {
      enemyWin = true;
    }

    //diagonal
    if (cells[0][0] == 1 && cells[1][1] == 1 && cells[2][2] == 1) {
      youWin = true;
    } else if (cells[0][0] == 2 && cells[1][1] == 2 && cells[2][2] == 2) {
      enemyWin = true;
    }

    if (cells[2][0] == 1 && cells[1][1] == 1 && cells[0][2] == 1) {
      youWin = true;
    } else if (cells[2][0] == 2 && cells[1][1] == 2 && cells[0][2] == 2) {
      enemyWin = true;
    }

    if(youWin){
      _showFinishGame(true);
    }else if (enemyWin){
      _showFinishGame(false);
    }
    
    bool todasJogadasFeitas = true;
    for (var rows in cells) {
      for (var cell in rows) {
        if (cell == 0) {
          todasJogadasFeitas = false;
          break;
        }
      }
    }

    if(todasJogadasFeitas){
      _showFinishGame(null);
    }
  }

  void _showFinishGame(bool? youWin){
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context){
        return AlertDialog(
          title: const Text("Digite a mensagem para enviar"),
          content: Text(youWin == true ? "Você ganhou" : youWin == null ? "empate" : "Você perdeu"),
          actions: [
            ElevatedButton(
              child: const Text("Fechar"),
              onPressed: (){
                Navigator.of(context).pop();
                setState(() {
                  creator = null;
                  minhaVez = false;
                  cells = [
                    [0, 0, 0],
                    [0, 0, 0],
                    [0, 0, 0]
                  ];
                });
              },
            )
          ],
        );
      }
    );
  }

  void _sendMessage() async {
    TextEditingController controller = TextEditingController();
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context){
        return AlertDialog(
          title: const Text("Digite a mensagem para enviar"),
          content: TextField(controller: controller),
          actions: [
            ElevatedButton(
              child: const Text("Enviar"),
              onPressed: (){
                Navigator.of(context).pop();
                _sendAction('chat', 
                {'message': '${creator!.creator ? "p1" : "p2"}|${controller.text}'});
              },
            )
          ],
        );
      }
    );
  }
}