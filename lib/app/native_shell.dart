import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/native_models.dart';
import '../services/native_store.dart';
import '../services/smart_engine.dart';
import '../services/noql_service.dart';

const bg=Color(0xFF0B0F1A),surface=Color(0xFF171E2E),surface2=Color(0xFF1D2740),gold=Color(0xFFE8A94C),gold2=Color(0xFFF4C777),teal=Color(0xFF4FBDBA),teal2=Color(0xFF78D9D6),rose=Color(0xFFE8674F),dim=Color(0xFF8B93A7);
class NativeShell extends StatefulWidget{const NativeShell({super.key});@override State<NativeShell> createState()=>_NativeShellState();}
class _NativeShellState extends State<NativeShell>{NativeData?data;GliaStore?store;Object?error;@override void initState(){super.initState();load();}Future<void>load()async{try{final d=NativeData.fromJson(await rootBundle.loadString('assets/generated_original_deck.json'),await rootBundle.loadString('assets/generated_persian_pack.json'));final s=GliaStore(d);await s.init();if(mounted)setState((){data=d;store=s;});}catch(e){if(mounted)setState(()=>error=e);}}@override Widget build(BuildContext c){if(error!=null)return MaterialApp(home:Scaffold(body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.error_outline,size:60,color:rose),Text('$error'),FilledButton(onPressed:load,child:const Text('تلاش دوباره'))]))));if(data==null||store==null)return const MaterialApp(home:Scaffold(body:Center(child:CircularProgressIndicator())));return AnimatedBuilder(animation:store!,builder:(context,child){
  final themeSeed=switch(store!.settings.theme){
    'cyan'=>teal2,
    'purple'=>const Color(0xFFB58CFF),
    'emerald'=>const Color(0xFF37D6A0),
    'rose'=>const Color(0xFFFF7B6B),
    'blue'=>const Color(0xFF6EA8FF),
    _=>gold,
  };
  final cs=ColorScheme.fromSeed(seedColor:themeSeed,brightness:Brightness.dark).copyWith(
    primary:themeSeed,
    onPrimary:const Color(0xFF08101A),
    secondary:themeSeed,
    onSecondary:const Color(0xFF08101A),
    surface:surface,
    onSurface:Colors.white,
    surfaceContainerHighest:surface2,
    onSurfaceVariant:const Color(0xFFD2D6E0),
    outline:const Color(0xFF596276),
  );
  final text=Colors.white;
  final muted=const Color(0xFFB8C0D0);
  return MaterialApp(
    debugShowCheckedModeBanner:false,title:'گلیا کنکور',
    theme:ThemeData(
      useMaterial3:true,brightness:Brightness.dark,
      scaffoldBackgroundColor:bg,colorScheme:cs,
      cardTheme:CardThemeData(color:surface,surfaceTintColor:Colors.transparent,margin:const EdgeInsets.symmetric(vertical:4)),
      appBarTheme:AppBarTheme(backgroundColor:bg,foregroundColor:text,surfaceTintColor:Colors.transparent),
      drawerTheme:DrawerThemeData(backgroundColor:surface),
      navigationBarTheme:NavigationBarThemeData(backgroundColor:surface,indicatorColor:surface2,labelTextStyle:WidgetStatePropertyAll(TextStyle(color:Colors.white,fontWeight:FontWeight.w700))),
      listTileTheme:ListTileThemeData(textColor:text,subtitleTextStyle:TextStyle(color:muted),iconColor:teal2),
      inputDecorationTheme:InputDecorationTheme(labelStyle:TextStyle(color:muted),hintStyle:TextStyle(color:muted)),
      textTheme:ThemeData(brightness:Brightness.dark).textTheme.apply(bodyColor:text,displayColor:text),
    ),
    home:MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(store!.settings.fontScale.clamp(.8,1.5))),child:Directionality(textDirection:TextDirection.rtl,child:Home(data:data!,store:store!))),
  );
});}}
class Logo extends StatelessWidget{const Logo({super.key,this.size=52});final double size;@override Widget build(BuildContext c)=>ClipRRect(borderRadius:BorderRadius.circular(size*.2),child:Image.asset('assets/glia_icon.png',width:size,height:size,fit:BoxFit.cover,errorBuilder:(context,error,stackTrace)=>Container(width:size,height:size,color:gold,child:const Icon(Icons.psychology,color:Colors.white))));}
class Home extends StatefulWidget{const Home({super.key,required this.data,required this.store});final NativeData data;final GliaStore store;@override State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home>{int tab=0;void open(String t,List<LeitnerCard>x)=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LessonPicker(title:t,cards:x,store:widget.store)));Widget nav(String t,IconData i,VoidCallback f)=>ListTile(leading:Icon(i),title:Text(t),onTap:f);@override Widget build(BuildContext c)=>Scaffold(drawer:Drawer(child:SafeArea(child:ListView(children:[const SizedBox(height:10),const ListTile(leading:Logo(size:52),title:Text('گلیا کنکور',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900,color:teal2)),subtitle:Text('لایتنر هوشمند',style:TextStyle(color:dim))),const Divider(),nav('خانه',Icons.home,()=>setState(()=>tab=0)),nav('دسته‌ها',Icons.grid_view,()=>setState(()=>tab=1)),nav('آمار',Icons.insights,()=>setState(()=>tab=2)),nav('تنظیمات حرفه‌ای',Icons.settings,()=>setState(()=>tab=3)),nav('مرکز هوشمند',Icons.auto_awesome,(){Navigator.pop(context);Navigator.push(context,MaterialPageRoute(builder:(_)=>SmartCenter(data:widget.data,store:widget.store)));}),nav('یادگرفته‌ها',Icons.check_circle,(){Navigator.pop(context);Navigator.push(context,MaterialPageRoute(builder:(_)=>Status(data:widget.data,store:widget.store,known:true)));}),nav('نیازمند مرور',Icons.timelapse,(){Navigator.pop(context);Navigator.push(context,MaterialPageRoute(builder:(_)=>Status(data:widget.data,store:widget.store,known:false)));}),const Divider(),nav('کانال گلیا کنکور',Icons.telegram,()=>launchUrl(Uri.parse('https://t.me/Glia_konkor'),mode:LaunchMode.externalApplication))]))),body:IndexedStack(index:tab,children:[Dashboard(data:widget.data,store:widget.store,open:open),Categories(data:widget.data,store:widget.store,open:open),Stats(data:widget.data,store:widget.store),Settings(data:widget.data,store:widget.store)]),bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[NavigationDestination(icon:Icon(Icons.home),label:'خانه'),NavigationDestination(icon:Icon(Icons.grid_view),label:'دسته‌ها'),NavigationDestination(icon:Icon(Icons.insights),label:'آمار'),NavigationDestination(icon:Icon(Icons.settings),label:'تنظیمات')]));}
class Dashboard extends StatelessWidget{const Dashboard({super.key,required this.data,required this.store,required this.open});final NativeData data;final GliaStore store;final void Function(String,List<LeitnerCard>)open;@override Widget build(BuildContext c){final all=data.allCards,k=all.where((x)=>store.cardState[x.id]=='known').length,p=all.isEmpty?0.0:k/all.length;return ListView(padding:const EdgeInsets.all(16),children:[Row(children:[const Logo(size:58),const SizedBox(width:12),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('گلیا کنکور',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:teal2)),Text('باهوش یاد بگیر، با اعتماد پیش برو',style:TextStyle(color:dim))]))]),const SizedBox(height:14),Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(borderRadius:BorderRadius.circular(26),gradient:const LinearGradient(colors:[Color(0xFF152C45),Color(0xFF0D1727)])),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('هر روز یک قدم قوی‌تر',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900,color:gold2)),const SizedBox(height:8),const Text('سریع، سبک و کاملاً آفلاین با Flutter.',style:TextStyle(color:dim)),const SizedBox(height:16),Row(children:[SizedBox(width:80,height:80,child:CircularProgressIndicator(value:p,color:teal,strokeWidth:8)),const SizedBox(width:14),Expanded(child:Text('پیشرفت کلی: ${(p*100).round()}٪\n${store.reviewed} مرور · ${store.correct} پاسخ درست'))]),const SizedBox(height:16),Card(color:surface2,child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Icon(Icons.flag,color:gold2),const SizedBox(width:8),const Text('هدف امروز',style:TextStyle(fontWeight:FontWeight.w800)),const Spacer(),Text('${store.reviewed}/${store.settings.dailyGoal}',style:const TextStyle(color:teal2,fontWeight:FontWeight.w900))]),const SizedBox(height:8),LinearProgressIndicator(value:(store.reviewed/store.settings.dailyGoal).clamp(0.0,1.0),color:gold2)]))),const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>open('مرور همه کارت‌ها',List.of(all)),icon:const Icon(Icons.play_arrow),label:const Text('شروع مرور')))])) ,const SizedBox(height:12),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,crossAxisSpacing:10,mainAxisSpacing:10,children:[_cat('انگلیسی','${data.cards.where((x)=>x.category=='english').length}',teal,Icons.translate,()=>open('انگلیسی',data.cards.where((x)=>x.category=='english').toList())),_cat('افعال بی‌قاعده','${data.cards.where((x)=>x.category=='verbs').length}',const Color(0xFFA66CFF),Icons.sync_alt,()=>open('افعال بی‌قاعده',data.cards.where((x)=>x.category=='verbs').toList())),_cat('فارسی','${data.cards.where((x)=>x.category=='persian').length}',const Color(0xFF37D6A0),Icons.menu_book,()=>open('فارسی',data.cards.where((x)=>x.category=='persian').toList())),_cat('عربی','${data.cards.where((x)=>x.category=='arabic').length}',teal2,Icons.language,()=>open('عربی',data.cards.where((x)=>x.category=='arabic').toList())),_cat('پک فارسی','${data.persianPack.length}',gold2,Icons.auto_stories,()=>open('پک فارسی',data.persianPack)),_cat('املا و آزمون','${data.spelling.length}',rose,Icons.quiz,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>QuizPicker(data:data,store:store))))])]);}Widget _cat(String t,String n,Color co,IconData i,VoidCallback f)=>InkWell(onTap:f,child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:surface,borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i,color:co,size:28),const Spacer(),Text(t,style:const TextStyle(fontWeight:FontWeight.w900)),Text(n,style:const TextStyle(color:dim))])));}
class Categories extends StatelessWidget{const Categories({super.key,required this.data,required this.store,required this.open});final NativeData data;final GliaStore store;final void Function(String,List<LeitnerCard>)open;@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[const Text('همه دسته‌ها',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:12),for(final e in <Map<String,dynamic>>[{'t':'انگلیسی','cat':'english','i':Icons.translate,'c':teal},{'t':'افعال بی‌قاعده','cat':'verbs','i':Icons.sync_alt,'c':const Color(0xFFA66CFF)},{'t':'فارسی','cat':'persian','i':Icons.menu_book,'c':const Color(0xFF37D6A0)},{'t':'عربی','cat':'arabic','i':Icons.language,'c':teal2}])Card(child:ListTile(leading:Icon(e['i'] as IconData,color:e['c'] as Color),title:Text(e['t'] as String),subtitle:Text('${data.cards.where((x)=>x.category==e['cat']).length} کارت'),onTap:()=>open(e['t'] as String,data.cards.where((x)=>x.category==e['cat']).toList()))),Card(child:ListTile(leading:const Icon(Icons.auto_stories,color:gold2),title:const Text('پک فارسی'),subtitle:Text('${data.persianPack.length} کارت'),onTap:()=>open('پک فارسی',data.persianPack))),Card(child:ListTile(leading:const Icon(Icons.quiz,color:rose),title:const Text('املا و آزمون'),subtitle:Text('${data.spelling.length} سؤال'),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>QuizPicker(data:data,store:store)))))]);}
class SmartCenter extends StatelessWidget {
  const SmartCenter({super.key, required this.data, required this.store});
  final NativeData data; final GliaStore store;
  @override Widget build(BuildContext c) {
    final cards=data.allCards; final ready=SmartEngine.readiness(store,cards); final weak=SmartEngine.weakLessons(store,cards); final due=cards.where((x)=>store.isDue(x.id)).length;
    return Scaffold(appBar:AppBar(title:const Text('مرکز هوشمند')),body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[const Icon(Icons.psychology_alt,size:46,color:teal2),const SizedBox(height:8),const Text('آمادگی هوشمند',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:10),Text('$ready٪',style:const TextStyle(fontSize:38,fontWeight:FontWeight.w900,color:gold2)),const SizedBox(height:8),LinearProgressIndicator(value:ready/100,color:teal2)]))),
      Card(child:ListTile(leading:const Icon(Icons.auto_awesome,color:gold2),title:const Text('مرور هوشمند'),subtitle:Text('$due کارت با اولویت بالا'),onTap:(){final q=SmartEngine.smartQueue(store,cards);Navigator.push(c,MaterialPageRoute(builder:(_)=>Study(title:'مرور هوشمند',cards:q,store:store,dueOnly:false)));})),
      Card(child:ListTile(leading:const Icon(Icons.psychology_alt,color:teal2),title:const Text('AI آفلاین گلیا · Noql'),subtitle:const Text('پیدا کردن کارت‌های معنایی مشابه، بدون اینترنت'),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>NoqlSearch(data:data,store:store))))),
      Card(child:ListTile(leading:const Icon(Icons.tune,color:teal2),title:const Text('آزمون تطبیقی'),subtitle:const Text('سختی سؤال بعدی با عملکردت تغییر می‌کند'),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>AdaptiveQuiz(data:data,store:store))))),
      Card(child:ListTile(leading:const Icon(Icons.nights_stay,color:Color(0xFFB58CFF)),title:const Text('شب قبل آزمون'),subtitle:const Text('مرور سریع کارت‌های ضعیف و پرتکرار'),onTap:(){final q=SmartEngine.smartQueue(store,cards,limit:30);Navigator.push(c,MaterialPageRoute(builder:(_)=>Study(title:'شب قبل آزمون',cards:q,store:store,dueOnly:false)));})),
      Card(child:ListTile(leading:const Icon(Icons.local_fire_department,color:rose),title:const Text('چالش روزانه'),subtitle:const Text('۲۰ کارت با تمرکز روی نقاط ضعف'),onTap:(){final q=SmartEngine.challenge(store,cards);Navigator.push(c,MaterialPageRoute(builder:(_)=>Study(title:'چالش روزانه',cards:q,store:store,dueOnly:false)));})),
      Card(child:ListTile(leading:const Icon(Icons.bolt,color:gold2),title:const Text('مرور سریع ۱۰ کارت'),subtitle:const Text('یک جلسه کوتاه و فشرده'),onTap:(){final q=SmartEngine.smartQueue(store,cards,limit:10);Navigator.push(c,MaterialPageRoute(builder:(_)=>Study(title:'مرور سریع',cards:q,store:store,dueOnly:false)));})),
      Card(child:ListTile(leading:const Icon(Icons.warning_amber,color:rose),title:const Text('فقط کارت‌های سخت'),subtitle:const Text('کارت‌هایی که بیشترین نیاز به تمرین دارند'),onTap:(){final q=SmartEngine.rank(store,cards).where((x)=>x.difficulty==SmartDifficulty.hard||x.difficulty==SmartDifficulty.critical).take(30).map((x)=>x.card).toList();Navigator.push(c,MaterialPageRoute(builder:(_)=>Study(title:'کارت‌های سخت',cards:q,store:store,dueOnly:false)));})),
      Card(child:ListTile(leading:const Icon(Icons.schedule,color:teal2),title:const Text('فقط مرورهای موعددار'),subtitle:Text('$due کارت موعددار'),onTap:(){final q=cards.where((x)=>store.isDue(x.id)).toList();Navigator.push(c,MaterialPageRoute(builder:(_)=>Study(title:'مرورهای موعددار',cards:q,store:store,dueOnly:false)));})),

      Card(child:ListTile(leading:const Icon(Icons.timer,color:gold2),title:const Text('تمرکز / پومودورو'),subtitle:const Text('جلسه ۲۵ دقیقه‌ای مطالعه بدون حواس‌پرتی'),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>FocusTimer(store:store))))),
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('مربی هوشمند',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const SizedBox(height:8),Text(SmartEngine.coach(store,cards),style:const TextStyle(height:1.7)),]))),
      if(weak.isNotEmpty) Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('نقاط ضعف',style:TextStyle(fontWeight:FontWeight.w900)),...weak.entries.map((e)=>ListTile(dense:true,leading:const Icon(Icons.warning_amber,color:rose),title:Text(e.key),trailing:Text('${e.value} کارت')))]))),
    ]));
  }
}

class NoqlSearch extends StatefulWidget {
  const NoqlSearch({super.key, required this.data, required this.store});
  final NativeData data;
  final GliaStore store;
  @override State<NoqlSearch> createState() => _NoqlSearchState();
}

class _NoqlSearchState extends State<NoqlSearch> {
  final controller = TextEditingController();
  List<NoqlMatch> results = const [];
  bool loading = false;
  bool ready = false;
  @override void initState() { super.initState(); _init(); }
  Future<void> _init() async {
    final ok = await NoqlService.instance.init();
    if (mounted) setState(() => ready = ok);
  }
  Future<void> search() async {
    final query = controller.text.trim();
    if (query.isEmpty || loading) return;
    setState(() => loading = true);
    final r = await NoqlService.instance.similarCards(query, widget.data.allCards, limit: 10);
    if (mounted) setState(() { results = r; loading = false; });
  }
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI آفلاین گلیا')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.psychology_alt, color: teal2, size: 30), const SizedBox(width: 10), const Expanded(child: Text('Noql · موتور معنایی فارسی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), Icon(ready ? Icons.check_circle : Icons.hourglass_top, color: ready ? teal : gold2)]),
          const SizedBox(height: 10),
          const Text('مدل ۱۱.۹ میلیون پارامتری روی خود دستگاه اجرا می‌شود و برای پیدا کردن کارت‌های مشابه استفاده می‌شود.', style: TextStyle(color: dim, height: 1.7)),
        ]))),
        const SizedBox(height: 10),
        TextField(controller: controller, textInputAction: TextInputAction.search, onSubmitted: (_) => search(), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'یک کلمه یا مفهوم بنویس', hintText: 'مثلاً پذیرفتن، حافظه، فشار خون...', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: !ready || loading ? null : search, icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome), label: Text(loading ? 'در حال تحلیل...' : 'پیدا کن')),
        const SizedBox(height: 10),
        if (!ready) const Card(child: ListTile(leading: Icon(Icons.info_outline, color: gold2), title: Text('در حال آماده‌سازی AI'), subtitle: Text('مدل و نمایه به‌صورت آفلاین داخل APK قرار می‌گیرند.'))),
        for (final item in results) Card(child: ListTile(
          leading: CircleAvatar(backgroundColor: teal.withValues(alpha: .14), child: Text('\${(item.score * 100).round()}%', style: const TextStyle(color: teal2, fontSize: 11))),
          title: Text(item.card.front, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('\${item.card.back}\n\${item.card.lesson}', maxLines: 2, overflow: TextOverflow.ellipsis),
          isThreeLine: true,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Study(title: 'تمرین مشابه', cards: [item.card], store: widget.store, dueOnly: false))),
        )),
      ]),
    );
  }
}
class AdaptiveQuiz extends StatefulWidget { const AdaptiveQuiz({super.key,required this.data,required this.store}); final NativeData data; final GliaStore store; @override State<AdaptiveQuiz> createState()=>_AdaptiveQuizState(); }
class _AdaptiveQuizState extends State<AdaptiveQuiz> {
  late List<SpellingQuestion> qs; int i=0; int score=0; int? selected; bool sent=false;
  @override void initState(){super.initState();qs=List.of(widget.data.spelling)..shuffle();qs=qs.take(20).toList();}
  Future<void> pick(int n) async { if(sent)return; final ok=n==qs[i].correctIndex; setState((){selected=n;sent=true;if(ok)score++;}); await widget.store.answer(qs[i],ok); if(widget.store.settings.haptics)HapticFeedback.selectionClick(); }
  void next(){if(i+1>=qs.length){Navigator.pop(context);return;} setState((){i++;selected=null;sent=false;});}
  @override Widget build(BuildContext c){final x=qs[i];return Scaffold(appBar:AppBar(title:const Text('آزمون تطبیقی')),body:ListView(padding:const EdgeInsets.all(16),children:[LinearProgressIndicator(value:(i+1)/qs.length,color:teal2),const SizedBox(height:16),Text('سطح تطبیقی · امتیاز $score',style:const TextStyle(color:teal2,fontWeight:FontWeight.w800)),Card(child:Padding(padding:const EdgeInsets.all(18),child:Text(x.sentence,style:const TextStyle(fontSize:21,height:2,fontWeight:FontWeight.w700)))),for(int j=0;j<x.options.length;j++)Padding(padding:const EdgeInsets.only(bottom:8),child:FilledButton(onPressed:sent?null:()=>pick(j),style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(55),backgroundColor:!sent?surface:(j==x.correctIndex?teal:(j==selected?rose:surface))),child:Align(alignment:Alignment.centerRight,child:Text(x.options[j])))),if(sent)Card(child:Padding(padding:const EdgeInsets.all(14),child:Text(selected==x.correctIndex?'درست!':'اشتباه؛ پاسخ صحیح: ${x.options[x.correctIndex]}',style:TextStyle(fontWeight:FontWeight.w900,color:selected==x.correctIndex?teal:rose)))),if(sent)FilledButton(onPressed:next,child:Text(i+1==qs.length?'پایان':'سؤال بعدی'))]));}
}

class FocusTimer extends StatefulWidget { const FocusTimer({super.key,required this.store}); final GliaStore store; @override State<FocusTimer> createState()=>_FocusTimerState(); }
class _FocusTimerState extends State<FocusTimer> { int seconds=1500; bool running=false; Timer? timer; @override void dispose(){timer?.cancel();super.dispose();} void toggle(){if(running){timer?.cancel();setState(()=>running=false);}else{setState(()=>running=true);timer=Timer.periodic(const Duration(seconds:1),(_){if(seconds<=1){timer?.cancel();setState((){seconds=0;running=false;});}else{setState(()=>seconds--);}});}} void reset(){timer?.cancel();setState((){seconds=1500;running=false;});} @override Widget build(BuildContext c){final m=(seconds~/60).toString().padLeft(2,'0'),s=(seconds%60).toString().padLeft(2,'0');return Scaffold(appBar:AppBar(title:const Text('تمرکز')),body:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(Icons.self_improvement,size:64,color:teal2),const SizedBox(height:20),Text('$m:$s',style:const TextStyle(fontSize:64,fontWeight:FontWeight.w900,color:gold2)),const SizedBox(height:20),FilledButton.icon(onPressed:toggle,icon:Icon(running?Icons.pause:Icons.play_arrow),label:Text(running?'توقف':'شروع')),TextButton(onPressed:reset,child:const Text('بازنشانی'))])));}}

class Stats extends StatelessWidget{const Stats({super.key,required this.data,required this.store});final NativeData data;final GliaStore store;@override Widget build(BuildContext c){final all=data.allCards,k=all.where((x)=>store.cardState[x.id]=='known').length,a=store.reviewed==0?0:(store.correct/store.reviewed*100).round();return ListView(padding:const EdgeInsets.all(16),children:[const Text('آمار عملکرد',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:12),Card(child:ListTile(title:const Text('مرور'),trailing:Text('${store.reviewed}'))),Card(child:ListTile(title:const Text('دقت'),trailing:Text('$a٪'))),Card(child:ListTile(title:const Text('استریک'),trailing:Text('${store.streak} روز'))),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('پیشرفت لایتنر'),const SizedBox(height:8),Text('$k از ${all.length} کارت یاد گرفته شده'),const SizedBox(height:8),LinearProgressIndicator(value:all.isEmpty?0:k/all.length,color:teal)]))) ]);}}

class LessonPicker extends StatefulWidget {
  const LessonPicker({super.key, required this.title, required this.cards, required this.store});
  final String title;
  final List<LeitnerCard> cards;
  final GliaStore store;

  @override
  State<LessonPicker> createState() => _LessonPickerState();
}

class _LessonPickerState extends State<LessonPicker> {
  String selectedLesson = 'همه درس‌ها';
  String search = '';
  String filterMode = 'due';

  List<String> get lessons {
    final values = widget.cards.map((x) => x.lesson.trim()).where((x) => x.isNotEmpty).toSet().toList();
    values.sort((a, b) => a.compareTo(b));
    return ['همه درس‌ها', ...values];
  }

  List<LeitnerCard> get filtered {
    final q = search.trim().toLowerCase();
    return widget.cards.where((card) {
      final lessonOk = selectedLesson == 'همه درس‌ها' || card.lesson == selectedLesson;
      final box = widget.store.boxFor(card.id);
      final dueOk = filterMode == 'all' ||
          (filterMode == 'due' && widget.store.isDue(card.id)) ||
          (filterMode == 'weak' && box <= 2) ||
          (filterMode == 'known' && widget.store.isKnown(card.id));
      final searchOk = q.isEmpty ||
          card.lesson.toLowerCase().contains(q) ||
          card.front.toLowerCase().contains(q) ||
          card.back.toLowerCase().contains(q);
      return lessonOk && dueOk && searchOk;
    }).toList();
  }

  void start() {
    final xs = filtered;
    if (xs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برای این فیلتر کارتی پیدا نشد.')),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Study(title: selectedLesson, cards: xs, store: widget.store, dueOnly: filterMode == 'due'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xs = filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('انتخاب درس و فیلتر')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'جست‌وجوی درس یا کارت',
                  hintText: 'مثلاً Lesson 1',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => search = v),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: DropdownButtonFormField<String>(
                initialValue: filterMode,
                decoration: const InputDecoration(labelText: 'حالت مطالعه', border: InputBorder.none),
                items: const [
                  DropdownMenuItem(value: 'due', child: Text('هوشمند: فقط موعددار')),
                  DropdownMenuItem(value: 'weak', child: Text('تقویتی: کارت‌های ضعیف')),
                  DropdownMenuItem(value: 'known', child: Text('مرور تثبیتی: یادگرفته‌ها')),
                  DropdownMenuItem(value: 'all', child: Text('آزاد: همه کارت‌ها')),
                ],
                onChanged: (v) => setState(() => filterMode = v ?? 'due'),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: DropdownButtonFormField<String>(
                initialValue: selectedLesson,
                decoration: const InputDecoration(
                  labelText: 'درس',
                  border: InputBorder.none,
                ),
                items: lessons.map((lesson) => DropdownMenuItem(value: lesson, child: Text(lesson))).toList(),
                onChanged: (v) => setState(() => selectedLesson = v ?? 'همه درس‌ها'),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.filter_alt, color: teal2),
              title: Text('${xs.length} کارت آماده است'),
              subtitle: Text(selectedLesson == 'همه درس‌ها' ? 'همه درس‌ها' : selectedLesson),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: xs.isEmpty ? null : start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('شروع مطالعه'),
          ),
        ],
      ),
    );
  }
}

class QuizPicker extends StatefulWidget {
  const QuizPicker({super.key, required this.data, required this.store});
  final NativeData data;
  final GliaStore store;

  @override
  State<QuizPicker> createState() => _QuizPickerState();
}

class _QuizPickerState extends State<QuizPicker> {
  String selectedLesson = 'همه درس‌ها';
  String search = '';
  bool unansweredOnly = false;
  bool shuffle = true;

  List<String> get lessons {
    final values = widget.data.spelling.map((x) => x.lesson.trim()).where((x) => x.isNotEmpty).toSet().toList();
    values.sort((a, b) => a.compareTo(b));
    return ['همه درس‌ها', ...values];
  }

  List<SpellingQuestion> get filtered {
    final q = search.trim().toLowerCase();
    return widget.data.spelling.where((question) {
      final lessonOk = selectedLesson == 'همه درس‌ها' || question.lesson == selectedLesson;
      final answered = widget.store.answerLog.containsKey(question.id);
      final answerOk = !unansweredOnly || !answered;
      final searchOk = q.isEmpty ||
          question.lesson.toLowerCase().contains(q) ||
          question.sentence.toLowerCase().contains(q);
      return lessonOk && answerOk && searchOk;
    }).toList();
  }

  void start() {
    final xs = filtered;
    if (xs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برای این فیلتر سؤالی پیدا نشد.')),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Quiz(data: widget.data, store: widget.store, questions: xs, shuffle: shuffle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xs = filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('انتخاب درس آزمون')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'جست‌وجوی درس یا سؤال',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => search = v),
              ),
            ),
          ),
          Card(
            child: DropdownButtonFormField<String>(
              initialValue: selectedLesson,
              decoration: const InputDecoration(
                labelText: 'درس آزمون',
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
              ),
              items: lessons.map((lesson) => DropdownMenuItem(value: lesson, child: Text(lesson))).toList(),
              onChanged: (v) => setState(() => selectedLesson = v ?? 'همه درس‌ها'),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: unansweredOnly,
              onChanged: (v) => setState(() => unansweredOnly = v),
              secondary: const Icon(Icons.pending_actions),
              title: const Text('فقط سؤال‌های حل‌نشده'),
              subtitle: Text(unansweredOnly ? 'پاسخ‌داده‌شده‌ها حذف می‌شوند' : 'همه سؤال‌های این درس'),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: shuffle,
              onChanged: (v) => setState(() => shuffle = v),
              secondary: const Icon(Icons.shuffle),
              title: const Text('ترتیب تصادفی'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.quiz, color: rose),
              title: Text('${xs.length} سؤال آماده است'),
              subtitle: Text(selectedLesson),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: xs.isEmpty ? null : start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('شروع آزمون'),
          ),
        ],
      ),
    );
  }
}

class Study extends StatefulWidget {
  const Study({super.key, required this.title, required this.cards, required this.store, this.dueOnly = true});
  final String title;
  final List<LeitnerCard> cards;
  final GliaStore store;
  final bool dueOnly;

  @override
  State<Study> createState() => _StudyState();
}

class _StudyState extends State<Study> {
  late List<LeitnerCard> deck;
  int index = 0;
  bool flip = false;

  @override
  void initState() {
    super.initState();
    deck = List.of(widget.cards);
    if (widget.dueOnly) deck.removeWhere((x) => !widget.store.isDue(x.id));
    if (widget.store.settings.shuffle) deck.shuffle();
  }

  Future<void> rate(CardResult result) async {
    if (deck.isEmpty) return;
    final card = deck[index];
    await widget.store.rateCard(card, result);
    deck.removeAt(index);
    if (result == CardResult.review) deck.add(card);
    if (deck.isNotEmpty) index %= deck.length;
    setState(() => flip = false);
    if (widget.store.settings.haptics) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (deck.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.celebration, size: 70, color: gold2),
              const Text('همه کارت‌ها بررسی شدند 🎉'),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('بازگشت'),
              ),
            ],
          ),
        ),
      );
    }

    final card = deck[index];
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${index + 1} / ${deck.length}',
            style: const TextStyle(color: dim),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (index + 1) / deck.length,
            color: gold2,
          ),
          const SizedBox(height: 15),
          GestureDetector(
            onTap: () => setState(() => flip = !flip),
            child: AnimatedContainer(
              duration: Duration(
                milliseconds: widget.store.settings.motion ? 280 : 1,
              ),
              constraints: const BoxConstraints(minHeight: 310),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  colors: [Color(0xFF152C45), Color(0xFF0D1727)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(card.lesson, style: const TextStyle(color: teal2)),
                  const Spacer(),
                  Text(
                    flip ? card.back : card.front,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: flip ? 23 : 32,
                      fontWeight: FontWeight.w900,
                      color: flip ? Colors.white : gold2,
                      height: 1.7,
                    ),
                  ),
                  if (flip && card.extra.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      card.extra,
                      style: const TextStyle(color: teal2),
                    ),
                  ],
                  const Spacer(),
                  const Text(
                    'لمس کن تا برگردد',
                    style: TextStyle(color: dim),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _action('دوباره', rose, () => rate(CardResult.review)),
              const SizedBox(width: 6),
              _action('بعداً', gold2, () => rate(CardResult.later)),
              const SizedBox(width: 6),
              _action(
                'یاد گرفتم',
                const Color(0xFF37D6A0),
                () => rate(CardResult.known),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(String title, Color color, VoidCallback onPressed) {
    return Expanded(
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color.withValues(alpha: .14),
          foregroundColor: color,
        ),
        child: Text(title),
      ),
    );
  }
}

class Quiz extends StatefulWidget{const Quiz({super.key,required this.data,required this.store,required this.questions,this.shuffle=true});final NativeData data;final GliaStore store;final List<SpellingQuestion> questions;final bool shuffle;@override State<Quiz> createState()=>_QuizState();}
class _QuizState extends State<Quiz>{
  late List<SpellingQuestion> q;
  int i=0;
  int? sel;
  bool sent=false;

  @override
  void initState(){super.initState();q=List.of(widget.questions);if(widget.shuffle)q.shuffle();}

  Future<void> answer(int n) async {
    if(sent)return;
    final ok=n==q[i].correctIndex;
    setState((){sel=n;sent=true;});
    await widget.store.answer(q[i],ok);
    if(widget.store.settings.haptics) HapticFeedback.selectionClick();
    if(widget.store.settings.sound) SystemSound.play(SystemSoundType.click);
    if(widget.store.settings.autoNext) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if(mounted && sent) next();
    }
  }

  void next(){
    if(i+1>=q.length){Navigator.pop(context);return;}
    setState((){i++;sel=null;sent=false;});
  }

  @override
  Widget build(BuildContext c){
    final x=q[i];
    final ok=sent&&sel==x.correctIndex;
    return Scaffold(
      appBar:AppBar(title:const Text('املا و آزمون')),
      body:ListView(
        padding:const EdgeInsets.all(16),
        children:[
          LinearProgressIndicator(value:(i+1)/q.length,color:gold2),
          const SizedBox(height:14),
          Text('${i+1} / ${q.length}',style:Theme.of(c).textTheme.bodySmall),
          const SizedBox(height:8),
          Card(child:Padding(
            padding:const EdgeInsets.all(18),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(x.lesson,style:const TextStyle(color:teal2,fontWeight:FontWeight.w800)),
              const SizedBox(height:8),
              Text(x.sentence,style:const TextStyle(fontSize:21,height:2,fontWeight:FontWeight.w700)),
            ]),
          )),
          const SizedBox(height:10),
          for(int j=0;j<x.options.length;j++)
            Padding(
              padding:const EdgeInsets.only(bottom:8),
              child:FilledButton(
                onPressed:sent?null:()=>answer(j),
                style:FilledButton.styleFrom(
                  minimumSize:const Size.fromHeight(55),
                  backgroundColor:!sent?surface:(j==x.correctIndex?teal:(j==sel?rose:surface)),
                  foregroundColor:Colors.white,
                ),
                child:Align(alignment:Alignment.centerRight,child:Text(x.options[j])),
              ),
            ),
          if(sent) Card(
            color:ok?teal.withValues(alpha:.14):rose.withValues(alpha:.14),
            child:Padding(
              padding:const EdgeInsets.all(16),
              child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Icon(ok?Icons.check_circle:Icons.cancel,color:ok?teal:rose),
                const SizedBox(width:10),
                Expanded(child:Text(
                  ok?'درست گفتی! پاسخ صحیح همین گزینه است.':'اشتباه بود. پاسخ صحیح: ${x.options[x.correctIndex]}',
                  style:TextStyle(fontWeight:FontWeight.w800,color:ok?teal:rose),
                )),
              ]),
            ),
          ),
          if(sent) const SizedBox(height:8),
          if(sent) FilledButton.icon(
            onPressed:next,
            icon:const Icon(Icons.arrow_forward),
            label:Text(i+1==q.length?'پایان آزمون':'سؤال بعدی'),
          ),
        ],
      ),
    );
  }
}
class Status extends StatelessWidget{const Status({super.key,required this.data,required this.store,required this.known});final NativeData data;final GliaStore store;final bool known;@override Widget build(BuildContext c){final xs=data.allCards.where((x)=>known?store.cardState[x.id]=='known':store.cardState[x.id]=='review'||store.cardState[x.id]=='later').toList();return Scaffold(appBar:AppBar(title:Text(known?'یادگرفته‌ها':'نیازمند مرور')),body:ListView.builder(itemCount:xs.length,itemBuilder:(_,i)=>ListTile(title:Text(xs[i].front),subtitle:Text(xs[i].back))));}}
class Settings extends StatefulWidget {
  const Settings({super.key,required this.data,required this.store});
  final NativeData data;
  final GliaStore store;
  @override State<Settings> createState()=>_SettingsState();
}

class _SettingsState extends State<Settings> {
  Future<void> backup() async {
    final raw=const JsonEncoder.withIndent('  ').convert(widget.store.backup());
    await SharePlus.instance.share(ShareParams(files:[XFile.fromData(utf8.encode(raw),mimeType:'application/json',name:'glia-backup.json')],text:'پشتیبان گلیا کنکور'));
  }
  Future<void> restore() async {
    final r=await FilePicker.pickFiles(type:FileType.custom,allowedExtensions:['json'],withData:true);
    if(r==null)return; final bytes=r.files.single.bytes; if(bytes==null)return;
    await widget.store.restore(Map<String,dynamic>.from(jsonDecode(utf8.decode(bytes))));
  }
  Future<void> reset() async => widget.store.resetProgress();
  Future<void> setS(GliaSettings s) async => widget.store.updateSettings(s);
  @override Widget build(BuildContext c) {
    final s=widget.store.settings;
    return ListView(padding:const EdgeInsets.all(16),children:[
      const Text('تنظیمات حرفه‌ای',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),
      const SizedBox(height:8),
      const Text('ظاهر، سرعت، تعامل و پشتیبان‌گیری؛ کاملاً آفلاین.',style:TextStyle(color:dim)),
      Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('رنگ برنامه',style:TextStyle(fontWeight:FontWeight.w800)),
        const SizedBox(height:10),
        Wrap(spacing:8,runSpacing:8,children:[
          _theme('amber','طلایی',gold2,s.theme), _theme('cyan','فیروزه‌ای',teal2,s.theme),
          _theme('purple','بنفش',const Color(0xFFB58CFF),s.theme), _theme('emerald','سبز',const Color(0xFF37D6A0),s.theme),
          _theme('rose','رز',const Color(0xFFFF7B6B),s.theme), _theme('blue','آبی',const Color(0xFF6EA8FF),s.theme),
        ]),
      ]))),
      _sw('انیمیشن‌ها',s.motion,(v)=>setS(s.copyWith(motion:v)),Icons.animation),
      _sw('بازخورد لمسی',s.haptics,(v)=>setS(s.copyWith(haptics:v)),Icons.vibration),
      _sw('صدای تعامل',s.sound,(v)=>setS(s.copyWith(sound:v)),Icons.volume_up),
      _sw('رفتن خودکار به سؤال بعدی',s.autoNext,(v)=>setS(s.copyWith(autoNext:v)),Icons.skip_next),
      _sw('Shuffle هوشمند',s.shuffle,(v)=>setS(s.copyWith(shuffle:v)),Icons.shuffle),
      _sw('حالت کم‌مصرف',s.lowPower,(v)=>setS(s.copyWith(lowPower:v)),Icons.battery_saver),
      _sl('مکث کارت',s.delay.toDouble(),1000,8000,14,(v)=>setS(s.copyWith(delay:v.round()))),
      _sl('اندازه متن',s.fontScale,.8,1.5,14,(v)=>setS(s.copyWith(fontScale:v))),
      _sl('هدف روزانه',s.dailyGoal.toDouble(),10,100,18,(v)=>setS(s.copyWith(dailyGoal:v.round()))),
      Card(child:Column(children:[
        ListTile(leading:const Icon(Icons.ios_share,color:teal),title:const Text('پشتیبان‌گیری'),onTap:backup),
        ListTile(leading:const Icon(Icons.restore,color:gold2),title:const Text('بازیابی'),onTap:restore),
        ListTile(leading:const Icon(Icons.delete_sweep,color:rose),title:const Text('ریست کامل'),onTap:reset),
      ])),
      const Card(child:ListTile(title:Text('Native / Offline'),subtitle:Text('۲۱۵۱ کارت · ۶۳۹ سؤال · ۴۳۴ کارت پک فارسی'))),
    ]);
  }
  Widget _sw(String t,bool v,ValueChanged<bool> f,IconData i)=>Card(child:SwitchListTile(value:v,onChanged:f,secondary:Icon(i),title:Text(t)));
  Widget _theme(String id,String label,Color color,String selected)=>InkWell(onTap:()=>setS(widget.store.settings.copyWith(theme:id)),borderRadius:BorderRadius.circular(14),child:Container(width:92,padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:color.withValues(alpha:.12),borderRadius:BorderRadius.circular(14),border:Border.all(color:selected==id?color:Colors.transparent,width:2)),child:Column(children:[CircleAvatar(radius:14,backgroundColor:color),const SizedBox(height:6),Text(label,style:TextStyle(color:color,fontWeight:FontWeight.w800))])));
  Widget _sl(String t,double v,double a,double b,int d,ValueChanged<double> f)=>Card(child:Padding(padding:const EdgeInsets.all(10),child:Column(children:[Row(children:[Expanded(child:Text(t)),Text(t=='هدف روزانه'?'${v.round()}':'${(v*100).round()}٪',style:const TextStyle(color:teal2,fontWeight:FontWeight.w800))]),Slider(value:v.clamp(a,b),min:a,max:b,divisions:d,onChanged:f)])));
}