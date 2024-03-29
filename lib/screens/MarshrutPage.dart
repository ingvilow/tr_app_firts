// @dart=2.9

import 'package:fl_app/models/RouteWithStops.dart';
import 'package:fl_app/service/TransportService.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../main.dart';

import 'HomeSceen.dart';
import 'InfoForUsers.dart';
import 'MapPage.dart';
import 'NotifScreen.dart';
import 'SearchPage.dart';
import 'Settings.dart';
import 'StopsPage.dart';

class MarshrutsPage extends StatefulWidget {
  final int ttId;
  final List<RouteWithStops> routes;

  const MarshrutsPage({Key key, this.ttId, this.routes}) : super(key: key);

  @override
  _MarshrutsPageState createState() => _MarshrutsPageState();
}

class _MarshrutsPageState extends State<MarshrutsPage> {
  Box<RouteWithStops> favoriteRoutesBox;
  TransportService service = getIt<TransportService>();

  List<RouteWithStops> _routes = [];
  List<RouteWithStops> _routesToDisplay = [];

  @override
  void initState() {
    favoriteRoutesBox = Hive.box(favoritesBox);
    service.getMarshrutWithStops(widget.ttId).then((value) {
      setState(() {
        _routes.addAll(value);
        _routesToDisplay = _routes;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(
              Icons.favorite,
            ),
            onPressed: () {
              Navigator.pushNamed(context, 'favorite');
            },
          ),
        ],
        elevation: 0.0,
        title: Text(
          AppLocalizations.of(context).name,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 20 * textScale),
        ),
      ),
      body: (_routes == null)
          ? CircularProgressIndicator()
          : ValueListenableBuilder(
              valueListenable: favoriteRoutesBox.listenable(),
              builder: (context, Box<RouteWithStops> box, _) {
                return ListView.builder(
                  itemCount: _routesToDisplay.length + 1,
                  itemBuilder: (context, index) {
                    return index == 0 ? _searchBar() : _listItem(index - 1);
                  },
                );
              },
            ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: Colors.grey,
                ), onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );},
              ),
              IconButton(
                  icon: Icon(Icons.home, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Homescreen()),
                    );
                  }),
              IconButton(
                  icon: Icon(Icons.favorite, color: Colors.grey),
                  onPressed: () {
                    Navigator.pushNamed(context, 'favorite');
                  }),
              IconButton(
                  icon: Icon(Icons.map, color: Colors.grey), onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapPage()),
                );
              }),
            ]),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
             DrawerHeader(
              decoration: BoxDecoration(
              ),
              child: Center(child: Text( 'Дорис-Ассистент.Волгоград', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),)),
            ),
            ListTile(
              leading: Icon(Icons.message, color: Colors.grey,),
              title:  Text(
                AppLocalizations.of(context).menu,
                style: GoogleFonts.montserrat(fontSize: 14.0 * textScale),
              ),
              onTap: () async {
                await launch("mailto: tvolganet@gmail.com");
              },
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.grey),
              title:  Text(
                AppLocalizations.of(context).menu1,
                style: GoogleFonts.montserrat(fontSize: 14.0 * textScale),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InfoForUsers()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications_active, color: Colors.grey),
              title: Text(
                AppLocalizations.of(context).name4,
                style: GoogleFonts.montserrat(fontSize: 14.0 * textScale),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotifScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  //меняет иконку
  Widget getIcon(int index) {
    if (favoriteRoutesBox.containsKey(index)) {
      return Icon(Icons.favorite, color: Colors.red);
    }
    return Icon(Icons.favorite_border);
  }

  //добавляет в избранное
  void onFavoritePress(int index) {
    if (favoriteRoutesBox.containsKey(index)) {
      favoriteRoutesBox.deleteAt(_routes[index].route.ttId);
      print('THE NEW IDS HERE');
      return;
    }
    favoriteRoutesBox.put(index, _routes[index]);
    print(_routes);
  }

  //фетчится список маршрутов из АПИ и алгоритма
  _listItem(index) {
    final textScale = MediaQuery.of(context).textScaleFactor;
    return ListTile(
      title: Text(_routesToDisplay[index].route.mrTitle, style: TextStyle(
        fontSize: 16 * textScale,)),
      leading: Text(
        _routesToDisplay[index].route.mrNum,
        style: TextStyle(
            fontSize: 20 * textScale, color: Colors.green, fontWeight: FontWeight.bold, ),
      ),
      trailing: IconButton(
            icon: getIcon(index),
            onPressed: () => onFavoritePress(index),
          ),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => StopPage(
                      routeWithStops: _routes[index],
                    )));
      },
      //сраный костыль для остановок. Жать надо дооооолго
      onLongPress: (){
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => StopSerachFavs(
                )));
      },
    );
  }

  //поиск по названию маршрута. Не чувствителен к регистру, не чувствителен к последовательности набираемых букв
  _searchBar() {
    print('test1');
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        decoration: InputDecoration(
          hintText:  AppLocalizations.of(context).name10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (text) {
          text = text.toLowerCase();
          setState(() {
            print('object');
            _routesToDisplay = _routes.where((element) {
              var routesTitle = element.route.mrTitle.toLowerCase();
              print(routesTitle);
              return routesTitle.contains(text);
            }).toList();
          });
        },
      ),
    );
  }
}
