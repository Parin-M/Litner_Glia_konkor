import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/native_models.dart';
import '../services/native_store.dart';
import '../services/noql_service.dart';
import '../services/user_content_store.dart';

const _bg = Color(0xFF0B0F1A);
const _surface = Color(0xFF171E2E);
const _surface2 = Color(0xFF1D2740);
const _gold = Color(0xFFE8A94C);
const _teal = Color(0xFF78D9D6);
const _rose = Color(0xFFE8674F);
const _muted = Color(0xFF9AA5B8);

class GliaNativeV2 extends StatefulWidget {
  const GliaNativeV2({super.key});
  @override State<GliaNativeV2> createState() => _GliaNativeV2State();
}

class _GliaNativeV2State extends State<GliaNativeV2> {
  NativeData? data;
  GliaStore? store;
  late final UserContentStore user;
  Object? error;

  @override
  void initState() {
    super.initState();
    user = UserContentStore();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = NativeData.fromJson(
        await rootBundle.loadString('assets/generated_original_deck.json'),
        await rootBundle.loadString('assets/generated_persian_pack.json'),
      );
      final s = GliaStore(d);
      await s.init();
      await user.init();
      if (mounted) setState(() { data = d; store = s; error = null; });
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return MaterialApp(home: Scaffold(body: Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 60, color: _rose),
          const SizedBox(height: 12), Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 16), FilledButton(onPressed: _load, child: const Text('تلاش دوباره')),
        ]),
      ))));
    }
    if (data == null || store == null) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }

    return AnimatedBuilder(
      animation: Listenable.merge([store!, user]),
      builder: (context, _) {
        final seed = _themeColor(store!.settings.theme);
        final cs = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark).copyWith(
          primary: seed, secondary: seed, surface: _surface, onSurface: Colors.white,
          surfaceContainerHighest: _surface2, outline: const Color(0xFF566177),
        );
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'گلیا کنکور',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: _bg,
            colorScheme: cs,
            pageTransitionsTheme: const PageTransitionsTheme(builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            }),
            cardTheme: const CardThemeData(color: _surface, surfaceTintColor: Colors.transparent),
            appBarTheme: const AppBarTheme(backgroundColor: _bg, foregroundColor: Colors.white, surfaceTintColor: Colors.transparent),
            inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), labelStyle: TextStyle(color: _muted), hintStyle: TextStyle(color: _muted)),
          ),
          home: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(store!.settings.fontScale.clamp(.8, 1.6))),
            child: Directionality(textDirection: TextDirection.rtl, child: HomeV2(data: data!, store: store!, user: user)),
          ),
        );
      },
    );
  }

  Color _themeColor(String theme) => switch (theme) {
        'cyan' => const Color(0xFF78D9D6),
        'purple' => const Color(0xFFB58CFF),
        'emerald' => const Color(0xFF37D6A0),
        'rose' => const Color(0xFFFF7B6B),
        'blue' => const Color(0xFF6EA8FF),
        'orange' => const Color(0xFFFFA94D),
        _ => _gold,
      };
}

class HomeV2 extends StatefulWidget {
  const HomeV2({super.key, required this.data, required this.store, required this.user});
  final NativeData data; final GliaStore store; final UserContentStore user;
  @override State<HomeV2> createState() => _HomeV2State();
}

class _HomeV2State extends State<HomeV2> {
  int tab = 0;

  void _openDeck(UserDeck deck) => Navigator.push(context, MaterialPageRoute(builder: (_) => UserDeckScreen(deck: deck, store: widget.user, glia: widget.store)));

  @override
  Widget build(BuildContext context) {
    final builtIn = widget.data.allCards.length;
    final learned = widget.data.allCards.where((c) => widget.store.isKnown(c.id)).length;
    final progress = builtIn == 0 ? 0.0 : learned / builtIn;
    return Scaffold(
      appBar: AppBar(title: const Text('گلیا کنکور', style: TextStyle(fontWeight: FontWeight.w900))),
      drawer: Drawer(child: SafeArea(child: ListView(children: [
        const SizedBox(height: 12),
        const ListTile(leading: Icon(Icons.psychology_alt, color: _teal, size: 34), title: Text('گلیا کنکور', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19)), subtitle: Text('لایتنر + کارت‌های شخصی + AI آفلاین')),
        const Divider(),
        _nav('خانه', Icons.home, () => setState(() => tab = 0)),
        _nav('کارت‌ها و دسته‌های من', Icons.style, () => setState(() => tab = 1)),
        _nav('آزمون', Icons.quiz, () => _openQuiz()),
        _nav('هوش مصنوعی آفلاین', Icons.auto_awesome, () => _openAi()),
        _nav('تنظیمات و پشتیبان‌گیری', Icons.settings, () => setState(() => tab = 2)),
      ]))),
      body: IndexedStack(index: tab, children: [
        _dashboard(context, progress),
        LibraryHome(data: widget.data, glia: widget.store, user: widget.user),
        SettingsV2(glia: widget.store, user: widget.user),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.style), label: 'کارت‌های من'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'تنظیمات'),
        ],
      ),
    );
  }

  Widget _nav(String title, IconData icon, VoidCallback onTap) => ListTile(leading: Icon(icon), title: Text(title), onTap: () { Navigator.pop(context); onTap(); });

  Widget _dashboard(BuildContext context, double progress) {
    final due = widget.data.allCards.where((x) => widget.store.isDue(x.id)).length + widget.user.cards.where((x) => x.isDue).length;
    return ListView(padding: const EdgeInsets.all(16), children: [
      TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: Duration(milliseconds: widget.store.settings.lowPower ? 120 : 650), builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1-v)*18), child: child)), child: Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('هر روز یک قدم قوی‌تر', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: _gold)),
        const SizedBox(height: 7), const Text('همه‌چیز آفلاین؛ از مرور تا کارت‌های شخصی و موتور هوشمند.', style: TextStyle(color: _muted, height: 1.7)),
        const SizedBox(height: 18), Row(children: [SizedBox(width: 82, height: 82, child: CircularProgressIndicator(value: progress, strokeWidth: 8, color: _teal)), const SizedBox(width: 15), Expanded(child: Text('${(progress*100).round()}٪ پیشرفت در بسته اصلی\n$due کارت موعد مرور دارند', style: const TextStyle(fontWeight: FontWeight.w800, height: 1.8)))]),
        const SizedBox(height: 16), FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BuiltInStudyPicker(data: widget.data, store: widget.store))), icon: const Icon(Icons.play_arrow), label: const Text('شروع مرور هوشمند')),
      ])))),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: _quick(Icons.add_card, 'کارت جدید', _teal, () => _addCardFlow())), const SizedBox(width: 10), Expanded(child: _quick(Icons.create_new_folder, 'دسته جدید', _gold, () => _addDeckFlow()))]),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: _quick(Icons.quiz, 'آزمون من', _rose, _openQuiz)), const SizedBox(width: 10), Expanded(child: _quick(Icons.auto_awesome, 'AI آفلاین', const Color(0xFFB58CFF), _openAi))]),
      const SizedBox(height: 16),
      const Text('دسته‌های شخصی', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      if (widget.user.decks.isEmpty) const Card(child: ListTile(leading: Icon(Icons.style), title: Text('هنوز دسته‌ای نساخته‌ای'), subtitle: Text('از «دسته جدید» شروع کن و کارت‌های خودت را اضافه کن.'))),
      for (final deck in widget.user.decks.take(6)) Card(child: ListTile(leading: CircleAvatar(backgroundColor: Color(deck.color), child: const Icon(Icons.style, color: Colors.black)), title: Text(deck.name, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${widget.user.cardsFor(deck.id).length} کارت'), trailing: const Icon(Icons.chevron_left), onTap: () => _openDeck(deck))),
    ]);
  }

  Widget _quick(IconData icon, String title, Color color, VoidCallback tap) => Card(child: InkWell(onTap: tap, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 9), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)))]))));

  Future<void> _addDeckFlow() async {
    final name = await _textDialog('نام دسته جدید', 'مثلاً زیست‌شناسی فصل ۱');
    if (name == null) return;
    final d = await widget.user.addDeck(name);
    if (mounted) _openDeck(d);
  }

  Future<void> _addCardFlow() async {
    if (widget.user.decks.isEmpty) {
      await _addDeckFlow();
      if (widget.user.decks.isEmpty) return;
    }
    final deck = widget.user.decks.first;
    if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => CardEditor(deck: deck, store: widget.user)));
  }

  Future<String?> _textDialog(String title, String hint) async {
    final c = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: Text(title), content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: hint)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('تأیید'))]));
    c.dispose();
    return value;
  }

  void _openQuiz() => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizHome(data: widget.data, glia: widget.store, user: widget.user)));
  void _openAi() => Navigator.push(context, MaterialPageRoute(builder: (_) => AiAllCards(data: widget.data, glia: widget.store, user: widget.user)));
}

class LibraryHome extends StatelessWidget {
  const LibraryHome({super.key, required this.data, required this.glia, required this.user});
  final NativeData data; final GliaStore glia; final UserContentStore user;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Row(children: [const Expanded(child: Text('کارت‌ها و دسته‌های من', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900))), FilledButton.icon(onPressed: () async { final c = await _deckDialog(context); if (c != null) await user.addDeck(c); }, icon: const Icon(Icons.add), label: const Text('دسته'))]),
    const SizedBox(height: 12),
    if (user.decks.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('برای شروع یک دسته بساز و بعد کارت‌های متنی یا تصویری اضافه کن.'))),
    for (final d in user.decks) Card(child: ListTile(leading: CircleAvatar(backgroundColor: Color(d.color), child: const Icon(Icons.style, color: Colors.black)), title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${user.cardsFor(d.id).length} کارت · لایتنر ۵ خانه‌ای'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserDeckScreen(deck: d, store: user, glia: glia)))),
    const Divider(height: 30),
    const Text('بسته‌های اصلی برنامه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
    const SizedBox(height: 8),
    Card(child: ListTile(leading: const Icon(Icons.menu_book, color: _teal), title: const Text('کارت‌های آماده گلیا'), subtitle: Text('${data.allCards.length} کارت'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BuiltInStudyPicker(data: data, store: glia))))),
  ]);
}

Future<String?> _deckDialog(BuildContext context) async {
  final c = TextEditingController();
  final result = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('دسته جدید'), content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'نام دسته')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')), FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('ساختن'))]));
  c.dispose();
  return result?.trim().isEmpty == true ? null : result;
}

class UserDeckScreen extends StatelessWidget {
  const UserDeckScreen({super.key, required this.deck, required this.store, required this.glia});
  final UserDeck deck; final UserContentStore store; final GliaStore glia;
  @override Widget build(BuildContext context) {
    final cards = store.cardsFor(deck.id);
    return Scaffold(appBar: AppBar(title: Text(deck.name), actions: [IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CardEditor(deck: deck, store: store))), icon: const Icon(Icons.add_card))]), body: cards.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.style_outlined, size: 65, color: _teal), const SizedBox(height: 12), const Text('این دسته هنوز کارت ندارد'), const SizedBox(height: 12), FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CardEditor(deck: deck, store: store))), icon: const Icon(Icons.add), label: const Text('افزودن کارت'))]) : ListView(padding: const EdgeInsets.all(12), children: [Card(child: ListTile(leading: const Icon(Icons.layers), title: Text('${cards.length} کارت'), subtitle: Text('موعد مرور: ${cards.where((x) => x.isDue).length} · خانه ۵: ${cards.where((x) => x.box == 5).length}'), trailing: FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserStudy(deck: deck, store: store))), child: const Text('مطالعه')))), for (final card in cards) Card(child: ListTile(leading: _thumb(card.frontImage), title: Text(card.front, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text('خانه ${card.box} · ${card.back}', maxLines: 2, overflow: TextOverflow.ellipsis), trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') Navigator.push(context, MaterialPageRoute(builder: (_) => CardEditor(deck: deck, store: store, card: card))); if (v == 'delete') store.deleteCard(card.id); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('ویرایش')), PopupMenuItem(value: 'delete', child: Text('حذف'))])))]));
  }
}

Widget _thumb(String? path, {double size = 48}) => path == null || path.isEmpty ? CircleAvatar(radius: size/2, backgroundColor: _surface2, child: const Icon(Icons.style)) : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(path), width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => CircleAvatar(radius: size/2, child: const Icon(Icons.broken_image))));

class CardEditor extends StatefulWidget {
  const CardEditor({super.key, required this.deck, required this.store, this.card});
  final UserDeck deck; final UserContentStore store; final UserCard? card;
  @override State<CardEditor> createState() => _CardEditorState();
}
class _CardEditorState extends State<CardEditor> {
  final front = TextEditingController(); final back = TextEditingController(); final extra = TextEditingController(); final lesson = TextEditingController();
  Uint8List? frontImage; Uint8List? backImage; String frontExt = 'jpg'; String backExt = 'jpg'; int box = 1;
  @override void initState() { super.initState(); final c=widget.card; if(c!=null){front.text=c.front;back.text=c.back;extra.text=c.extra;lesson.text=c.lesson;box=c.box;} }
  @override void dispose(){front.dispose();back.dispose();extra.dispose();lesson.dispose();super.dispose();}
  Future<void> _pick(bool isFront) async { final r=await FilePicker.pickFiles(type:FileType.image,withData:true); if(r==null||r.files.single.bytes==null)return; final f=r.files.single; setState((){if(isFront){frontImage=f.bytes;frontExt=f.extension??'jpg';}else{backImage=f.bytes;backExt=f.extension??'jpg';}}); }
  Future<void> _save() async { if(front.text.trim().isEmpty||back.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('رو و پشت کارت را وارد کن.')));return;} if(widget.card==null){await widget.store.addCard(deckId:widget.deck.id,front:front.text,back:back.text,extra:extra.text,lesson:lesson.text,frontImage:frontImage,frontExtension:frontExt,backImage:backImage,backExtension:backExt,box:box);}else{await widget.store.updateCard(widget.card!.copyWith(front:front.text,back:back.text,extra:extra.text,lesson:lesson.text,box:box),newFrontImage:frontImage,frontExtension:frontExt,newBackImage:backImage,backExtension:backExt);} if(mounted)Navigator.pop(context); }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.card==null?'کارت جدید':'ویرایش کارت')),body:ListView(padding:const EdgeInsets.all(16),children:[_field(front,'روی کارت','سؤال، لغت یا مفهوم'),const SizedBox(height:10),_imagePicker(true),const SizedBox(height:12),_field(back,'پشت کارت','پاسخ یا توضیح'),const SizedBox(height:10),_imagePicker(false),const SizedBox(height:12),_field(extra,'توضیح اضافه','اختیاری',maxLines:3),const SizedBox(height:10),_field(lesson,'درس / برچسب','مثلاً فصل ۲'),const SizedBox(height:10),Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('خانه شروع لایتنر',style:TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:6),DropdownButtonFormField<int>(initialValue:box,items:[for(int i=1;i<=5;i++)DropdownMenuItem(value:i,child:Text('خانه $i'))],onChanged:(v)=>setState(()=>box=v??1))])),const SizedBox(height:18),FilledButton.icon(onPressed:_save,icon:const Icon(Icons.save),label:const Text('ذخیره کارت'))]);
  Widget _field(TextEditingController c,String label,String hint,{int maxLines=1})=>TextField(controller:c,maxLines:maxLines,decoration:InputDecoration(labelText:label,hintText:hint));
  Widget _imagePicker(bool isFront){final bytes=isFront?frontImage:backImage;return Card(child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[if(bytes!=null)ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.memory(bytes,width:74,height:74,fit:BoxFit.cover)),if(bytes!=null)const SizedBox(width:10),Expanded(child:Text(isFront?'تصویر روی کارت':'تصویر پشت کارت',style:const TextStyle(fontWeight:FontWeight.w800))),OutlinedButton.icon(onPressed:()=>_pick(isFront),icon:const Icon(Icons.image),label:Text(bytes==null?'افزودن':'تغییر'))])));}
}

class UserStudy extends StatefulWidget { const UserStudy({super.key,required this.deck,required this.store}); final UserDeck deck; final UserContentStore store; @override State<UserStudy> createState()=>_UserStudyState(); }
class _UserStudyState extends State<UserStudy>{late List<UserCard> deck;int i=0;bool flip=false;
  @override void initState(){super.initState();deck=widget.store.cardsFor(widget.deck.id).where((c)=>c.isDue).toList();if(deck.isEmpty)deck=widget.store.cardsFor(widget.deck.id);}
  Future<void> rate(bool known)async{if(deck.isEmpty)return;final c=deck[i];await widget.store.rate(c,known);if(!known)deck.add(c);deck.removeAt(i);if(deck.isNotEmpty)i=0;setState(()=>flip=false);}
  @override Widget build(BuildContext context){if(deck.isEmpty)return Scaffold(appBar:AppBar(title:Text(widget.deck.name)),body:const Center(child:Text('کارت آماده‌ای برای مرور نیست.')));final c=deck[i];return Scaffold(appBar:AppBar(title:Text(widget.deck.name),actions:[Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Center(child:Text('خانه ${c.box}')))]),body:ListView(padding:const EdgeInsets.all(16),children:[LinearProgressIndicator(value:(i+1)/deck.length),const SizedBox(height:14),GestureDetector(onTap:(){setState(()=>flip=!flip);if(widget.store.cards.any((x)=>x.id==c.id)){}},child:AnimatedSwitcher(duration:Duration(milliseconds:widget.store.cards.length>0?280:1),child:Container(key:ValueKey(flip),constraints:const BoxConstraints(minHeight:360),padding:const EdgeInsets.all(22),decoration:BoxDecoration(borderRadius:BorderRadius.circular(28),gradient:const LinearGradient(colors:[Color(0xFF152C45),Color(0xFF0D1727)])),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(c.lesson.isEmpty?'کارت شخصی':c.lesson,style:const TextStyle(color:_teal)),const SizedBox(height:25),if((flip?c.backImage:c.frontImage)!=null)_thumb(flip?c.backImage:c.frontImage,size:150),const SizedBox(height:18),Text(flip?c.back:c.front,textAlign:TextAlign.center,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900,color:_gold,height:1.7)),if(flip&&c.extra.isNotEmpty)Padding(padding:const EdgeInsets.only(top:12),child:Text(c.extra,style:const TextStyle(color:_teal))) ]))),const SizedBox(height:12),Row(children:[Expanded(child:FilledButton(onPressed:()=>rate(false),style:FilledButton.styleFrom(backgroundColor:_rose),child:const Text('دوباره'))),const SizedBox(width:8),Expanded(child:FilledButton(onPressed:()=>rate(true),style:FilledButton.styleFrom(backgroundColor:_teal,foregroundColor:Colors.black),child:const Text('یاد گرفتم')))])]);}
}

class BuiltInStudyPicker extends StatefulWidget { const BuiltInStudyPicker({super.key,required this.data,required this.store}); final NativeData data;final GliaStore store;@override State<BuiltInStudyPicker> createState()=>_BuiltInStudyPickerState(); }
class _BuiltInStudyPickerState extends State<BuiltInStudyPicker>{String lesson='همه درس‌ها';String query='';String mode='due';List<String> get lessons=>['همه درس‌ها',...widget.data.allCards.map((c)=>c.lesson).where((x)=>x.isNotEmpty).toSet()];List<LeitnerCard> get filtered{final q=query.trim().toLowerCase();return widget.data.allCards.where((c){final l=lesson=='همه درس‌ها'||c.lesson==lesson;final m=mode=='all'||(mode=='due'&&widget.store.isDue(c.id))||(mode=='weak'&&widget.store.boxFor(c.id)<=2)||(mode=='known'&&widget.store.isKnown(c.id));final s=q.isEmpty||c.front.toLowerCase().contains(q)||c.back.toLowerCase().contains(q)||c.lesson.toLowerCase().contains(q);return l&&m&&s;}).toList();} @override Widget build(BuildContext context){final xs=filtered;return Scaffold(appBar:AppBar(title:const Text('انتخاب درس برای مرور')),body:ListView(padding:const EdgeInsets.all(16),children:[TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),labelText:'جست‌وجوی درس یا کارت'),onChanged:(v)=>setState(()=>query=v)),const SizedBox(height:10),DropdownButtonFormField<String>(initialValue:lesson,decoration:const InputDecoration(labelText:'درس'),items:lessons.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>lesson=v??'همه درس‌ها')),const SizedBox(height:10),DropdownButtonFormField<String>(initialValue:mode,decoration:const InputDecoration(labelText:'فیلتر'),items:const [DropdownMenuItem(value:'due',child:Text('موعد مرور')),DropdownMenuItem(value:'all',child:Text('همه')),DropdownMenuItem(value:'weak',child:Text('ضعیف‌ها')),DropdownMenuItem(value:'known',child:Text('یادگرفته‌ها'))],onChanged:(v)=>setState(()=>mode=v??'due')),const SizedBox(height:14),Card(child:ListTile(leading:const Icon(Icons.filter_alt,color:_teal),title:Text('${xs.length} کارت آماده است'),subtitle:Text(lesson))),const SizedBox(height:10),FilledButton.icon(onPressed:xs.isEmpty?null:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>BuiltInStudy(title:lesson,cards:xs,store:widget.store))),icon:const Icon(Icons.play_arrow),label:const Text('شروع مرور'))]);}}

class BuiltInStudy extends StatefulWidget { const BuiltInStudy({super.key,required this.title,required this.cards,required this.store});final String title;final List<LeitnerCard> cards;final GliaStore store;@override State<BuiltInStudy> createState()=>_BuiltInStudyState(); }
class _BuiltInStudyState extends State<BuiltInStudy>{late List<LeitnerCard> cards;int i=0;bool flip=false;@override void initState(){super.initState();cards=List.of(widget.cards);if(widget.store.settings.shuffle)cards.shuffle();}
Future<void> rate(CardResult result)async{final c=cards[i];await widget.store.rateCard(c,result);cards.removeAt(i);if(result==CardResult.review)cards.add(c);if(cards.isNotEmpty)i=0;setState(()=>flip=false);if(widget.store.settings.sound)SystemSound.play(SystemSoundType.click);if(widget.store.settings.haptics)HapticFeedback.selectionClick();}
@override Widget build(BuildContext context){if(cards.isEmpty)return Scaffold(appBar:AppBar(title:Text(widget.title)),body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.celebration,size:70,color:_gold),const SizedBox(height:10),const Text('مرور تمام شد 🎉'),FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('بازگشت'))]));final c=cards[i];final duration=widget.store.settings.lowPower?const Duration(milliseconds:1):Duration(milliseconds:(280/widget.store.settings.speed).round());return Scaffold(appBar:AppBar(title:Text(widget.title)),body:ListView(padding:const EdgeInsets.all(16),children:[Text('${i+1}/${cards.length}',style:const TextStyle(color:_muted)),const SizedBox(height:8),LinearProgressIndicator(value:(i+1)/cards.length,color:_gold),const SizedBox(height:15),GestureDetector(onTap:(){setState(()=>flip=!flip);if(widget.store.settings.sound)SystemSound.play(SystemSoundType.click);},child:AnimatedSwitcher(duration:duration,transitionBuilder:(child,animation)=>ScaleTransition(scale:animation,child:child),child:Container(key:ValueKey(flip),constraints:const BoxConstraints(minHeight:340),padding:const EdgeInsets.all(24),decoration:BoxDecoration(borderRadius:BorderRadius.circular(26),gradient:const LinearGradient(colors:[Color(0xFF152C45),Color(0xFF0D1727)])),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(c.lesson,style:const TextStyle(color:_teal)),const SizedBox(height:28),Text(flip?c.back:c.front,textAlign:TextAlign.center,style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900,color:_gold,height:1.7)),if(flip&&c.extra.isNotEmpty)Text(c.extra,style:const TextStyle(color:_teal)),const SizedBox(height:25),const Text('لمس کن تا پاسخ نمایش داده شود',style:TextStyle(color:_muted))]))),const SizedBox(height:12),Row(children:[Expanded(child:FilledButton(onPressed:()=>rate(CardResult.review),style:FilledButton.styleFrom(backgroundColor:_rose),child:const Text('دوباره'))),const SizedBox(width:7),Expanded(child:FilledButton(onPressed:()=>rate(CardResult.later),style:FilledButton.styleFrom(backgroundColor:_gold,foregroundColor:Colors.black),child:const Text('بعداً'))),const SizedBox(width:7),Expanded(child:FilledButton(onPressed:()=>rate(CardResult.known),style:FilledButton.styleFrom(backgroundColor:_teal,foregroundColor:Colors.black),child:const Text('یاد گرفتم')))])]);}}

class QuizHome extends StatefulWidget { const QuizHome({super.key,required this.data,required this.glia,required this.user});final NativeData data;final GliaStore glia;final UserContentStore user;@override State<QuizHome> createState()=>_QuizHomeState(); }
class _QuizHomeState extends State<QuizHome>{String source='all';String lesson='همه درس‌ها';String query='';int count=20;List<LeitnerCard> get all=>[...widget.data.allCards,...widget.user.cards.map((c)=>LeitnerCard(id:'u_${c.id}',front:c.front,back:c.back,extra:c.extra,category:'user',lesson:c.lesson,type:'user'))];List<LeitnerCard> get pool{final q=query.toLowerCase().trim();return all.where((c){final src=source=='all'||(source=='user'&&c.category=='user')||(source=='builtin'&&c.category!='user');final l=lesson=='همه درس‌ها'||c.lesson==lesson;final s=q.isEmpty||c.front.toLowerCase().contains(q)||c.back.toLowerCase().contains(q)||c.lesson.toLowerCase().contains(q);return src&&l&&s;}).toList();} @override Widget build(BuildContext context){final p=pool;final lessons=['همه درس‌ها',...all.map((c)=>c.lesson).where((x)=>x.isNotEmpty).toSet()];return Scaffold(appBar:AppBar(title:const Text('مرکز آزمون')),body:ListView(padding:const EdgeInsets.all(16),children:[const Text('آزمون فوری با پاسخ همان لحظه',style:TextStyle(fontSize:21,fontWeight:FontWeight.w900,color:_gold)),const SizedBox(height:8),const Text('می‌توانی کارت‌های آماده، کارت‌های خودت یا هر دو را امتحان کنی.',style:TextStyle(color:_muted,height:1.7)),const SizedBox(height:14),DropdownButtonFormField<String>(initialValue:source,decoration:const InputDecoration(labelText:'منبع سؤال'),items:const [DropdownMenuItem(value:'all',child:Text('همه کارت‌ها')),DropdownMenuItem(value:'builtin',child:Text('کارت‌های آماده')),DropdownMenuItem(value:'user',child:Text('کارت‌های من'))],onChanged:(v)=>setState(()=>source=v??'all')),const SizedBox(height:10),DropdownButtonFormField<String>(initialValue:lesson,decoration:const InputDecoration(labelText:'درس / برچسب'),items:lessons.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>lesson=v??'همه درس‌ها')),const SizedBox(height:10),TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),labelText:'فیلتر متنی'),onChanged:(v)=>setState(()=>query=v)),const SizedBox(height:10),DropdownButtonFormField<int>(initialValue:count,decoration:const InputDecoration(labelText:'تعداد سؤال'),items:const [10,20,30,50].map((x)=>DropdownMenuItem(value:x,child:Text('$x سؤال'))).toList(),onChanged:(v)=>setState(()=>count=v??20)),const SizedBox(height:14),Card(child:ListTile(leading:const Icon(Icons.quiz,color:_rose),title:Text('${p.length} کارت قابل آزمون'),subtitle:const Text('پاسخ درست/غلط بلافاصله بعد از انتخاب نمایش داده می‌شود.'))),const SizedBox(height:10),FilledButton.icon(onPressed:p.isEmpty?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>CardQuiz(cards:p.take(count).toList(),glia:widget.glia))),icon:const Icon(Icons.play_arrow),label:const Text('شروع آزمون'))]);}}

class CardQuiz extends StatefulWidget { const CardQuiz({super.key,required this.cards,required this.glia});final List<LeitnerCard> cards;final GliaStore glia;@override State<CardQuiz> createState()=>_CardQuizState(); }
class _CardQuizState extends State<CardQuiz>{late List<LeitnerCard> qs;int i=0;int score=0;int? selected;late List<String> options;
@override void initState(){super.initState();qs=List.of(widget.cards)..shuffle();_makeOptions();}
void _makeOptions(){final c=qs[i];final pool=qs.where((x)=>x.id!=c.id).map((x)=>x.back).where((x)=>x.isNotEmpty).toSet().toList()..shuffle();options=[c.back,...pool.take(3)]..shuffle();}
Future<void> answer(int n)async{if(selected!=null)return;final ok=options[n]==qs[i].back;setState(()=>selected=n);if(ok)score++;if(widget.glia.settings.haptics)HapticFeedback.selectionClick();if(widget.glia.settings.sound)SystemSound.play(SystemSoundType.click);}
void next(){if(i+1>=qs.length){Navigator.pop(context);return;}setState((){i++;selected=null;_makeOptions();});}
@override Widget build(BuildContext context){final c=qs[i];final ok=selected!=null&&options[selected!]==c.back;return Scaffold(appBar:AppBar(title:Text('آزمون · $score امتیاز')),body:ListView(padding:const EdgeInsets.all(16),children:[LinearProgressIndicator(value:(i+1)/qs.length),const SizedBox(height:14),Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[Text(c.lesson.isEmpty?'کارت':c.lesson,style:const TextStyle(color:_teal)),const SizedBox(height:12),Text(c.front,textAlign:TextAlign.center,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900,height:1.7))]))),const SizedBox(height:12),for(int n=0;n<options.length;n++)Padding(padding:const EdgeInsets.only(bottom:8),child:FilledButton(onPressed:selected==null?()=>answer(n):null,style:FilledButton.styleFrom(backgroundColor:selected==null?_surface:(options[n]==c.back?_teal:(n==selected?_rose:_surface)),foregroundColor:options[n]==c.back&&selected!=null?Colors.black:Colors.white,minimumSize:const Size.fromHeight(55)),child:Align(alignment:Alignment.centerRight,child:Text(options[n])))),if(selected!=null)Card(color:ok?_teal.withValues(alpha:.14):_rose.withValues(alpha:.14),child:ListTile(leading:Icon(ok?Icons.check_circle:Icons.cancel,color:ok?_teal:_rose),title:Text(ok?'درست گفتی!':'اشتباه بود',style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('پاسخ صحیح: ${c.back}'))),if(selected!=null)FilledButton(onPressed:next,child:Text(i+1==qs.length?'پایان':'سؤال بعدی'))]);}}

class AiAllCards extends StatefulWidget { const AiAllCards({super.key,required this.data,required this.glia,required this.user});final NativeData data;final GliaStore glia;final UserContentStore user;@override State<AiAllCards> createState()=>_AiAllCardsState(); }
class _AiAllCardsState extends State<AiAllCards>{final q=TextEditingController();List<NoqlMatch> results=[];bool loading=false;bool ready=false;late List<LeitnerCard> cards;
@override void initState(){super.initState();cards=[...widget.data.allCards,...widget.user.cards.map((c)=>LeitnerCard(id:'u_${c.id}',front:c.front,back:c.back,extra:c.extra,category:'user',lesson:c.lesson,type:'user'))];_init();}
Future<void> _init()async{final ok=await NoqlService.instance.init();if(mounted)setState(()=>ready=ok);}
Future<void> _search()async{if(q.text.trim().isEmpty||!ready||loading)return;setState(()=>loading=true);final r=await NoqlService.instance.similarCards(q.text.trim(),cards,limit:15);if(mounted)setState((){results=r;loading=false;});}
@override void dispose(){q.dispose();super.dispose();}
@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('AI آفلاین · دسترسی کامل به کارت‌ها')),body:ListView(padding:const EdgeInsets.all(16),children:[Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Row(children:[Icon(Icons.psychology_alt,color:_teal),SizedBox(width:8),Text('مغز محلی گلیا',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900))]),const SizedBox(height:8),Text('Noql روی خود دستگاه اجرا می‌شود و اکنون متن کارت‌های آماده + کارت‌های شخصی شما را برای جست‌وجوی معنایی می‌بیند.',style:const TextStyle(color:_muted,height:1.8)),const SizedBox(height:8),Text('${cards.length} کارت در اختیار موتور هوشمند است.',style:const TextStyle(color:_teal,fontWeight:FontWeight.w800))]))),const SizedBox(height:10),TextField(controller:q,textInputAction:TextInputAction.search,onSubmitted:(_)=>_search(),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),labelText:'از AI درباره کارت‌ها بپرس',hintText:'مثلاً کارت‌های مربوط به حافظه یا فشار...')),const SizedBox(height:10),FilledButton.icon(onPressed:!ready||loading?null:_search,icon:loading?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.auto_awesome),label:Text(loading?'در حال تحلیل...':'پیدا کن')),if(!ready)const Padding(padding:EdgeInsets.all(12),child:Text('مدل آفلاین آماده نشده است. برنامه بدون اینترنت هم باید کارهای اصلی را انجام دهد.',style:TextStyle(color:_muted))),const SizedBox(height:8),for(final r in results)Card(child:ListTile(leading:CircleAvatar(backgroundColor:_teal.withValues(alpha:.15),child:Text('${(r.score*100).round()}%',style:const TextStyle(fontSize:10,color:_teal))),title:Text(r.card.front,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${r.card.back}\n${r.card.lesson}',maxLines:3,overflow:TextOverflow.ellipsis),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SingleBuiltInCard(card:r.card,glia:widget.glia))))]));}
}

class SingleBuiltInCard extends StatelessWidget { const SingleBuiltInCard({super.key,required this.card,required this.glia});final LeitnerCard card;final GliaStore glia;@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('کارت هوشمند')),body:ListView(padding:const EdgeInsets.all(16),children:[Card(child:Padding(padding:const EdgeInsets.all(22),child:Column(children:[Text(card.lesson,style:const TextStyle(color:_teal)),const SizedBox(height:20),Text(card.front,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900,color:_gold),textAlign:TextAlign.center),const SizedBox(height:20),Text(card.back,style:const TextStyle(fontSize:21,height:1.8),textAlign:TextAlign.center),if(card.extra.isNotEmpty)Text(card.extra,style:const TextStyle(color:_teal))])))]);}

class SettingsV2 extends StatefulWidget { const SettingsV2({super.key,required this.glia,required this.user});final GliaStore glia;final UserContentStore user;@override State<SettingsV2> createState()=>_SettingsV2State(); }
class _SettingsV2State extends State<SettingsV2>{Future<void> _backup()async{final bytes=await widget.user.buildBackup(progress:widget.glia.backup());await SharePlus.instance.share(ShareParams(files:[XFile.fromData(bytes,mimeType:'application/zip',name:'glia_backup_${DateTime.now().millisecondsSinceEpoch}.glia')],text:'پشتیبان کامل گلیا کنکور'));}
Future<void> _restore()async{final r=await FilePicker.pickFiles(type:FileType.custom,allowedExtensions:['glia'],withData:true);if(r==null||r.files.single.bytes==null)return;try{await widget.user.restoreBackup(r.files.single.bytes!);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('کارت‌ها و تصاویر با موفقیت وارد شدند.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('بازیابی ناموفق: $e')));}}
Future<void> _set(GliaSettings s)async=>widget.glia.updateSettings(s);
@override Widget build(BuildContext context){final s=widget.glia.settings;return ListView(padding:const EdgeInsets.all(16),children:[const Text('تنظیمات حرفه‌ای',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900)),const SizedBox(height:12),Card(child:Column(children:[SwitchListTile(value:s.sound,onChanged:(v){_set(s.copyWith(sound:v));SystemSound.play(SystemSoundType.click);},secondary:const Icon(Icons.volume_up),title:const Text('صدای تعامل'),subtitle:const Text('کلیک و تعامل با کارت‌ها')) ,SwitchListTile(value:s.haptics,onChanged:(v){_set(s.copyWith(haptics:v));if(v)HapticFeedback.mediumImpact();},secondary:const Icon(Icons.vibration),title:const Text('بازخورد لمسی'),subtitle:const Text('ویبره کوتاه هنگام پاسخ و تعامل')),SwitchListTile(value:s.lowPower,onChanged:(v)=>_set(s.copyWith(lowPower:v)),secondary:const Icon(Icons.battery_saver),title:const Text('حالت کم‌مصرف'),subtitle:const Text('انیمیشن‌ها و پردازش‌های نمایشی سبک‌تر می‌شوند')),SwitchListTile(value:s.motion,onChanged:(v)=>_set(s.copyWith(motion:v)),secondary:const Icon(Icons.animation),title:const Text('انیمیشن‌های محیط'),subtitle:const Text('حرکت کارت، صفحات و انتقال‌ها')),SwitchListTile(value:s.shuffle,onChanged:(v)=>_set(s.copyWith(shuffle:v)),secondary:const Icon(Icons.shuffle),title:const Text('مرور تصادفی'))])),const SizedBox(height:12),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('مکث کارت پس از پاسخ',style:TextStyle(fontWeight:FontWeight.w900)),Text('${(s.delay/1000).round()} ثانیه',style:const TextStyle(color:_teal,fontSize:18,fontWeight:FontWeight.w900)),Slider(value:s.delay.toDouble(),min:0,max:10000,divisions:20,label:'${(s.delay/1000).toStringAsFixed(1)} ثانیه',onChanged:(v)=>_set(s.copyWith(delay:v.round())))]))),const SizedBox(height:12),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('اندازه فونت',style:TextStyle(fontWeight:FontWeight.w900)),Text('${(s.fontScale*100).round()}٪',style:const TextStyle(color:_teal,fontWeight:FontWeight.w900)),Slider(value:s.fontScale,min:.8,max:1.6,divisions:8,onChanged:(v)=>_set(s.copyWith(fontScale:v)))]))),const SizedBox(height:12),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('تم رنگی',style:TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:8),Wrap(spacing:8,runSpacing:8,children:[['amber',_gold],['cyan',_teal],['purple',const Color(0xFFB58CFF)],['emerald',const Color(0xFF37D6A0)],['rose',const Color(0xFFFF7B6B)],['blue',const Color(0xFF6EA8FF)],['orange',const Color(0xFFFFA94D)]].map((e)=>ChoiceChip(label:Text('●'),selected:s.theme==e[0],labelStyle:TextStyle(color:e[1] as Color,fontSize:20),onSelected:(_)=>_set(s.copyWith(theme:e[0] as String)))).toList())]))),const SizedBox(height:12),Card(child:Column(children:[ListTile(leading:const Icon(Icons.upload_file,color:_teal),title:const Text('Export کامل کارت‌ها'),subtitle:const Text('فرمت اختصاصی .glia؛ متن + تصاویر + دسته‌ها + وضعیت مرور'),onTap:_backup),ListTile(leading:const Icon(Icons.download,color:_gold),title:const Text('Import کارت‌ها'),subtitle:const Text('بازیابی مستقیم فایل .glia بدون نیاز به JSON'),onTap:_restore)])),const SizedBox(height:12),Card(child:ListTile(leading:const Icon(Icons.info_outline),title:const Text('حالت تاریک'),subtitle:const Text('پوسته روشن عمداً در این نسخه وجود ندارد.')))]);}}
