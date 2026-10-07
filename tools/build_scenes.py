"""One-time scene authoring helper. The game loads the resulting editable .tscn files."""
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parent.parent
def write(path,text):
    p=ROOT/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding='utf-8')
def q(v):return json.dumps(v,ensure_ascii=False)

class Scene:
    def __init__(self):self.exts=[];self.subs=[];self.nodes=[];self.cache={}
    def ext(self,path,kind='Texture2D'):
        if path not in self.cache:
            n=str(len(self.exts)+1);self.cache[path]=f'ExtResource("{n}")';self.exts.append(f'[ext_resource type="{kind}" path="res://{path}" id="{n}"]')
        return self.cache[path]
    def sub(self,kind,name,props):
        self.subs.append(f'[sub_resource type="{kind}" id="{name}"]\n'+props)
        return f'SubResource("{name}")'
    def node(self,name,kind,parent=None,props='',instance=None):
        s=f'[node name="{name}"'+(f' type="{kind}"' if kind else '')+(f' parent="{parent}"' if parent is not None else '')+(f' instance={instance}' if instance else '')+']'
        self.nodes.append(s+'\n'+props)
    def save(self,path):write(path,'[gd_scene load_steps=%d format=3]\n\n'% (len(self.exts)+len(self.subs)+1)+'\n\n'.join(self.exts+self.subs+self.nodes)+'\n')
    def root(self,name='UI',script=None):
        self.node(name,'Control',props='layout_mode = 3\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nmouse_filter = 2\ntheme = '+self.ext('resources/ui_theme.tres','Theme')+ ('\nscript = '+self.ext(script,'Script') if script else ''))
    def label(self,name,parent,text,box,size=13,color=None,align=None):
        props=rect(box)+'\nmouse_filter = 2\ntext = '+q(text)+'\ntheme_override_font_sizes/font_size = '+str(size)
        if color:props+='\ntheme_override_colors/font_color = '+color
        if align is not None:props+='\nhorizontal_alignment = '+str(align)
        self.node(name,'Label',parent,props)
    def panel(self,name,parent,box,style='panel'):
        self.node(name,'Panel',parent,rect(box)+'\nmouse_filter = 2\ntheme_override_styles/panel = '+self.ext('resources/'+style+'.tres','StyleBox'))
    def button(self,name,parent,text,box):
        self.node(name,'Button',parent,rect(box)+'\ntext = '+q(text)+'\nmouse_default_cursor_shape = 2')
    def image(self,name,parent,path,box):
        self.node(name,'TextureRect',parent,rect(box)+'\nmouse_filter = 2\ntexture = '+self.ext(path)+'\nexpand_mode = 1\nstretch_mode = 5')
    def color(self,name,parent,box,color):
        self.node(name,'ColorRect',parent,rect(box)+'\nmouse_filter = 2\ncolor = '+color)
    def bar(self,name,parent,box):
        self.node(name,'ProgressBar',parent,rect(box)+'\nmouse_filter = 2\nvalue = 100.0\nshow_percentage = false')

def rect(b):
    x,y,w,h=b;return f'layout_mode = 0\noffset_left = {x}.0\noffset_top = {y}.0\noffset_right = {x+w}.0\noffset_bottom = {y+h}.0'
GOLD='Color(0.91,0.79,0.53,1)';MUTED='Color(0.58,0.68,0.72,1)';CREAM='Color(0.94,0.93,0.86,1)'
write('resources/ui_font.tres','''[gd_resource type="FontVariation" load_steps=2 format=3]
[ext_resource type="FontFile" path="res://assets/fonts/MPLUS1p-Medium.ttf" id="1"]
[resource]
base_font = ExtResource("1")
''')
write('resources/title_font.tres','''[gd_resource type="FontVariation" load_steps=2 format=3]
[ext_resource type="FontFile" path="res://assets/fonts/ShipporiMincho-SemiBold.ttf" id="1"]
[resource]
base_font = ExtResource("1")
''')
for name,bg,border in [('panel','Color(0.027,0.063,0.102,0.96)','Color(0.48,0.49,0.42,1)'),('subtle','Color(0.025,0.054,0.081,0.88)','Color(0.22,0.32,0.34,0.9)'),('button','Color(0.043,0.09,0.13,1)','Color(0.29,0.37,0.36,1)'),('hover','Color(0.12,0.22,0.25,1)','Color(0.84,0.73,0.49,1)'),('focus','Color(0,0,0,0)','Color(0.9,0.81,0.59,1)'),('bar_bg','Color(0.07,0.13,0.16,1)','Color(0.12,0.21,0.23,1)'),('bar_fill','Color(0.32,0.68,0.61,1)','Color(0.50,0.84,0.69,1)')]:
    write('resources/'+name+'.tres',f'''[gd_resource type="StyleBoxFlat" format=3]
[resource]
bg_color = {bg}
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = {border}
corner_radius_top_left = 2
corner_radius_top_right = 2
corner_radius_bottom_left = 2
corner_radius_bottom_right = 2
content_margin_left = 8.0
content_margin_right = 8.0
''')
write('resources/ui_theme.tres','''[gd_resource type="Theme" load_steps=9 format=3]
[ext_resource type="Font" path="res://resources/ui_font.tres" id="1"]
[ext_resource type="StyleBox" path="res://resources/button.tres" id="2"]
[ext_resource type="StyleBox" path="res://resources/hover.tres" id="3"]
[ext_resource type="StyleBox" path="res://resources/focus.tres" id="4"]
[ext_resource type="StyleBox" path="res://resources/panel.tres" id="5"]
[ext_resource type="StyleBox" path="res://resources/subtle.tres" id="6"]
[ext_resource type="StyleBox" path="res://resources/bar_bg.tres" id="7"]
[ext_resource type="StyleBox" path="res://resources/bar_fill.tres" id="8"]
[resource]
default_font = ExtResource("1")
default_font_size = 13
Label/colors/font_color = Color(0.94,0.94,0.87,1)
Label/colors/font_outline_color = Color(0.025,0.045,0.07,1)
Label/constants/outline_size = 2
Button/colors/font_color = Color(0.89,0.89,0.81,1)
Button/colors/font_hover_color = Color(1,0.91,0.67,1)
Button/colors/font_focus_color = Color(1,0.92,0.69,1)
Button/colors/font_disabled_color = Color(0.34,0.43,0.45,1)
Button/styles/normal = ExtResource("2")
Button/styles/hover = ExtResource("3")
Button/styles/pressed = ExtResource("3")
Button/styles/focus = ExtResource("4")
Button/styles/disabled = ExtResource("6")
Panel/styles/panel = ExtResource("5")
ProgressBar/styles/background = ExtResource("7")
ProgressBar/styles/fill = ExtResource("8")
RichTextLabel/colors/default_color = Color(0.93,0.94,0.89,1)
RichTextLabel/constants/normal_outline_size = 1
RichTextLabel/constants/line_separation = 3
''')

# Four directional animated SpriteFrames stay editable in the inspector.
for character in ['terra','locke']:
    lines=[f'[gd_resource type="SpriteFrames" load_steps=14 format=3]\n[ext_resource type="Texture2D" path="res://assets/art/{character}_walk.png" id="1"]']
    for row,direction in enumerate(['down','left','right','up']):
        for col in range(3):lines.append(f'[sub_resource type="AtlasTexture" id="{direction}{col}"]\natlas = ExtResource("1")\nregion = Rect2({col*24}, {row*32}, 24, 32)')
    anim=[]
    for direction in ['down','left','right','up']:
        frames=', '.join('{"duration": 1.0, "texture": SubResource("'+direction+str(col)+'")}' for col in [1,0,1,2])
        anim.append('{"frames": ['+frames+'], "loop": true, "name": &"'+direction+'", "speed": 8.0}')
    lines.append('[resource]\nanimations = ['+', '.join(anim)+']')
    write('resources/'+character+'_frames.tres','\n\n'.join(lines))
    s=Scene();script=s.ext('scripts/player.gd','Script');frames=s.ext('resources/'+character+'_frames.tres','SpriteFrames');shadow=s.ext('assets/art/shadow.png')
    shape=s.sub('RectangleShape2D','Feet','size = Vector2(10, 7)')
    s.node('Player' if character=='terra' else 'Companion','CharacterBody2D',props='collision_layer = 2\ncollision_mask = '+('1' if character=='terra' else '0')+'\ny_sort_enabled = true\nscript = '+script+'\nis_companion = '+('false' if character=='terra' else 'true'))
    s.node('Shadow','Sprite2D','.',f'texture = {shadow}\nposition = Vector2(0, -2)')
    s.node('Appearance','AnimatedSprite2D','.',f'position = Vector2(0, -14)\nsprite_frames = {frames}\nanimation = &"down"\nframe = 0')
    s.node('Feet','CollisionShape2D','.',f'position = Vector2(0, -3)\nshape = {shape}')
    if character=='terra':
        s.node('Camera2D','Camera2D','.', 'position_smoothing_enabled = false\nlimit_smoothed = false\nposition = Vector2(0, -12)')
        s.node('InteractHint','Label','.', 'visible = false\nz_index = 40\noffset_left = -100.0\noffset_top = -46.0\noffset_right = 100.0\noffset_bottom = -29.0\ntext = "Z はなす"\nhorizontal_alignment = 1\ntheme = '+s.ext('resources/ui_theme.tres','Theme')+'\ntheme_override_font_sizes/font_size = 10\ntheme_override_colors/font_color = '+GOLD)
    s.save('scenes/actors/'+('player' if character=='terra' else 'companion')+'.tscn')

# Interactable prefabs: the per-instance exports define the gameplay.
for name,path,kind,marker,solid in [('npc','mog','talk','!',True),('chest','chest_closed','chest','◇',True),('encounter','wolf','enemy','!',False),('landmark','spark','sign','◇',False)]:
    s=Scene();shape=s.sub('CircleShape2D','Detection','radius = 15.0');body=s.sub('RectangleShape2D','Feet','size = Vector2(12, 8)')
    s.node(name.title(),'Area2D',props='collision_layer = 0\ncollision_mask = 2\nscript = '+s.ext('scripts/interactable.gd','Script')+'\nkind = '+q(kind))
    s.node('Shadow','Sprite2D','.', 'position = Vector2(0, -1)\ntexture = '+s.ext('assets/art/shadow.png'))
    s.node('Appearance','Sprite2D','.', 'position = Vector2(0, -11)\ntexture = '+s.ext('assets/art/'+path+'.png')+('\nscale = Vector2(0.55,0.55)' if name=='encounter' else ''))
    s.node('Detection','CollisionShape2D','.', 'shape = '+shape)
    if solid:
        s.node('Body','StaticBody2D','.', 'collision_layer = 1\ncollision_mask = 2')
        s.node('Feet','CollisionShape2D','Body', 'position = Vector2(0, -3)\nshape = '+body)
    s.node('Marker','Label','.', 'offset_left = -45.0\noffset_top = -43.0\noffset_right = 45.0\noffset_bottom = -25.0\nhorizontal_alignment = 1\ntext = '+q(marker)+'\ntheme = '+s.ext('resources/ui_theme.tres','Theme')+'\ntheme_override_font_sizes/font_size = 13\ntheme_override_colors/font_color = '+GOLD)
    s.save('scenes/actors/'+name+'.tscn')

s=Scene();s.node('Pine','StaticBody2D',props='collision_layer = 1\ncollision_mask = 2')
s.node('Canopy','Sprite2D','.', 'position = Vector2(0, -24)\ntexture = '+s.ext('assets/art/pine.png'))
s.node('Trunk','CollisionShape2D','.', 'position = Vector2(0, -7)\nshape = '+s.sub('RectangleShape2D','Trunk','size = Vector2(13, 17)'))
s.save('scenes/props/pine.tscn')

# HUD.
s=Scene();s.root('HUD');s.panel('Location','.',(12,10,174,43),'subtle');s.label('Name','Location','星灯りの村',(12,4,150,20),16);s.label('Subtitle','Location','LANTERN VILLAGE',(12,26,154,12),8,GOLD)
s.panel('Quest','.',(359,10,206,43),'subtle');s.label('Step','Quest','CHAPTER 01 / 星のかけら',(10,5,187,13),9,GOLD);s.label('Objective','Quest','広場のモグに話しかける',(10,20,188,17),11)
s.button('Menu','.', '記録帳', (573,10,55,24));s.nodes[-1]+='\nfocus_mode = 0'
s.button('Mute','.', '音 ON', (581,37,47,18));s.nodes[-1]+='\nfocus_mode = 0\ntheme_override_font_sizes/font_size = 9'
s.label('Gold','.', '75 G',(520,56,46,17),10,GOLD,2)
s.panel('Party','.',(12,304,252,44),'subtle')
for i,(name,texture) in enumerate([('ティナ','terra_portrait'),('ロック','locke_portrait')]):
    p='Party/Member'+str(i+1);s.node('Member'+str(i+1),'Control','Party',rect((i*126,0,126,44))+'\nmouse_filter = 2')
    s.image('Portrait',p,'assets/art/'+texture+'.png',(4,5,31,34));s.label('Name',p,name+' Lv.1',(39,4,83,14),10);s.label('HP',p,'120 / 120',(39,18,81,13),9,MUTED);s.bar('Health',p,(40,34,75,3))
s.label('Hint','.', 'WASD 移動   Shift 走る   Z 調べる   Esc 記録帳',(279,329,255,17),9,CREAM)
s.panel('Minimap','.',(536,271,92,73),'subtle');s.image('Map','Minimap','assets/art/town_minimap.png',(4,4,84,64));s.nodes[-1]=s.nodes[-1].replace('stretch_mode = 5','stretch_mode = 0')
s.color('Dot','Minimap',(37,37,4,4),GOLD);s.label('Toast','.', '',(135,62,370,24),12,GOLD,1);s.nodes[-1]+='\nvisible = false'
s.save('scenes/ui/hud.tscn')

# Dialogue panel, including all typewriter text and portraits.
s=Scene();s.root('Dialogue','scripts/dialogue.gd')
s.panel('Panel','.',(14,235,612,112));s.label('Speaker','Panel','モグ',(18,8,400,20),14,GOLD);s.image('Portrait','Panel','assets/art/mog.png',(15,35,47,52))
s.node('Text','RichTextLabel','Panel',rect((74,34,512,58))+'\nmouse_filter = 2\nbbcode_enabled = true\ntext = "ようこそ、星灯りの村へ。"\nscroll_active = false\ntheme_override_font_sizes/normal_font_size = 13')
s.label('Continue','Panel','Z / ENTER 次へ',(434,90,160,16),9,MUTED,2);s.label('Page','Panel','1 / 2',(18,91,70,13),9,MUTED)
s.button('Next','Panel','',(0,0,612,112));empty=s.sub('StyleBoxEmpty','Invisible','');s.nodes[-1]+='\nfocus_mode = 0\ntheme_override_styles/normal = '+empty+'\ntheme_override_styles/hover = '+empty+'\ntheme_override_styles/pressed = '+empty
s.save('scenes/ui/dialogue.tscn')

# Title. Village remains visible behind the left-aligned logo.
s=Scene();s.root('Title');s.color('Shade','.',(0,0,640,360),'Color(0.014,0.035,0.06,0.76)')
s.label('Eyebrow','.', 'A SMALL JOURNEY BENEATH THE STARS',(44,62,500,16),9,GOLD)
s.label('Logo','.', '星灯りの約束',(42,83,550,53),36,CREAM);s.nodes[-1]+='\ntheme_override_fonts/font = '+s.ext('resources/title_font.tres','Font')
s.label('EnglishTitle','.', 'A  P R O M I S E  I N  S T A R L I G H T',(46,143,480,19),10,GOLD)
s.color('Rule','.',(46,178,46,1),GOLD);s.label('Description','.', '消えた灯りを、もう一度。\nティナとロックの、小さな冒険。',(46,192,480,41),13)
s.node('Buttons','Control','.',rect((46,251,363,34))+'\nmouse_filter = 2');s.button('New','Buttons','はじめから  →',(0,0,173,32));s.button('Continue','Buttons','つづきから',(185,0,142,32))
s.label('Status','.', '',(47,290,478,20),11,GOLD)
s.label('Controls','.', '矢印 / WASD  移動      Z / ENTER  決定      ESC  記録帳',(46,323,530,17),9,MUTED)
s.label('Edition','.', 'CHAPTER 01\n星のかけら',(488,83,116,45),11,GOLD,2)
s.label('Credit','.', 'FFVI SPRITE STUDY  /  GODOT',(404,338,222,12),8,MUTED,2)
s.save('scenes/ui/title.tscn')

s=Scene();s.root('Menu');s.nodes[-1]+='\nvisible = false';s.color('Dim','.',(0,0,640,360),'Color(0.01,0.03,0.06,0.65)');s.panel('Card','.',(80,23,480,314));s.label('Heading','Card','旅の記録',(20,12,435,30),22,GOLD);s.label('Small','Card','JOURNAL  /  PARTY & INVENTORY',(22,44,435,16),9,MUTED)
for i,t in enumerate(['terra_portrait','locke_portrait']):
    p='Card/Member'+str(i+1);s.node('Member'+str(i+1),'Control','Card',rect((24+i*220,72,210,77))+'\nmouse_filter = 2');s.image('Portrait',p,'assets/art/'+t+'.png',(0,0,52,62));s.label('Stats',p,'',(64,0,150,75),12)
s.label('Inventory','Card','',(24,150,428,43),12,GOLD);s.label('Objective','Card','',(24,197,428,20),12)
for name,title,x,y,w in [('Resume','冒険にもどる',24,234,135),('Save','記録する',171,234,135),('Load','記録から再開',318,234,138),('Potion','ポーションを使う',24,267,183),('Title','タイトルへ',318,267,138)]:s.button(name,'Card',title,(x,y,w,25))
s.label('Status','.', '',(76,339,488,18),11,GOLD,1);s.nodes[-1]=s.nodes[-1].replace('parent="."','parent="Card"').replace('offset_left = 76.0','offset_left = 14.0').replace('offset_top = 339.0','offset_top = 294.0').replace('offset_right = 564.0','offset_right = 466.0').replace('offset_bottom = 357.0','offset_bottom = 312.0')
s.save('scenes/ui/menu.tscn')

s=Scene();s.root('Shop');s.nodes[-1]+='\nvisible = false';s.color('Dim','.',(0,0,640,360),'Color(0.01,0.03,0.06,0.67)');s.panel('Card','.',(161,67,318,227));s.label('Title','Card','旅人の道具屋',(22,14,274,29),21,GOLD);s.label('Stock','Card','',(23,59,274,93),13);s.label('Message','Card','旅のお供に、ポーションはいかが？',(23,158,279,21),11,MUTED);s.button('Buy','Card','買う  25 G',(23,188,162,26));s.button('Close','Card','閉じる',(199,188,95,26));s.save('scenes/ui/shop.tscn')

s=Scene();s.root('Ending');s.nodes[-1]+='\nvisible = false';s.color('Dim','.',(0,0,640,360),'Color(0.01,0.03,0.06,0.8)');s.panel('Card','.',(112,47,416,265));s.label('Eyebrow','Card','CHAPTER 01  /  COMPLETE',(30,20,356,16),10,GOLD,1);s.label('Title','Card','灯りは、ここに。',(20,49,376,44),29,CREAM,1);s.nodes[-1]+='\ntheme_override_fonts/font = '+s.ext('resources/title_font.tres','Font');s.label('Text','Card','星のかけらは村に戻り、\nふたりの旅は、また次の朝へ。',(30,108,356,42),13,CREAM,1);s.label('Stats','Card','',(30,164,356,44),11,GOLD,1);s.button('Continue','Card','村にもどる',(111,223,194,28));s.save('scenes/ui/ending.tscn')

# Command battle. Everything visible is a saved scene node.
s=Scene();s.root('Battle','scripts/battle.gd');s.nodes[-1]+='\nvisible = false'
s.node('Backdrop','TextureRect','.',rect((0,0,640,245))+'\nmouse_filter = 2\ntexture = '+s.ext('assets/art/battle_forest.png')+'\nexpand_mode = 1\nstretch_mode = 6')
s.node('BossBackdrop','TextureRect','.',rect((0,0,640,245))+'\nvisible = false\nmouse_filter = 2\ntexture = '+s.ext('assets/art/battle_boss.png')+'\nexpand_mode = 1\nstretch_mode = 6')
s.color('GroundShade','.',(0,0,640,245),'Color(0.03,0.06,0.10,0.14)')
for name,tex,pos,scale in [('Enemy1','wolf',(154,158),1.8),('Enemy2','wasp',(258,176),1.8)]:s.node(name,'Sprite2D','.',f'texture = {s.ext("assets/art/"+tex+".png")}\nposition = Vector2{pos}\nscale = Vector2({scale},{scale})')
s.node('BossEnemy','Sprite2D','.', 'visible = false\ntexture = '+s.ext('assets/art/guardian.png')+'\nposition = Vector2(196,150)\nscale = Vector2(1.65,1.65)')
for name,tex,pos in [('Hero1','terra',(471,126)),('Hero2','locke',(523,178))]:
    atlas=s.sub('AtlasTexture',name+'Texture','atlas = '+s.ext('assets/art/'+tex+'_walk.png')+'\nregion = Rect2(24,32,24,32)');s.node(name,'Sprite2D','.',f'texture = {atlas}\nposition = Vector2{pos}\nscale = Vector2(2,2)')
for i in [1,2]:
    s.button('EnemyTarget'+str(i),'.','',(88 if i==1 else 225,81 if i==1 else 127,132 if i==1 else 81,116 if i==1 else 80));empty=s.sub('StyleBoxEmpty','TargetEmpty'+str(i),'');s.nodes[-1]+='\nfocus_mode = 0\ntheme_override_styles/normal = '+empty+'\ntheme_override_styles/hover = '+empty+'\ntheme_override_styles/pressed = '+empty
s.label('Target','.', '▼',(0,0,20,20),14,GOLD,1);s.label('Damage','.', '',(0,0,70,26),23,GOLD,1)
s.panel('Log','.',(16,12,524,32),'subtle');s.label('Text','Log','魔物があらわれた！',(12,7,508,20),12)
s.label('Turn','.', 'TURN  01',(548,20,74,17),10,GOLD,2)
s.color('Footer','.',(0,238,640,122),'Color(0.022,0.046,0.071,1)')
s.panel('Commands','.',(12,234,156,115));s.label('Title','Commands','ティナの行動',(10,5,136,17),11,GOLD)
for i,(name,text) in enumerate([('Attack','たたかう'),('Magic','ファイア   6 MP'),('Guard','ぼうぎょ / MP回復'),('Potion','ポーション'),('Flee','にげる')]):
    s.button(name,'Commands',text,(6,24+i*17,144,17));s.nodes[-1]+='\ntheme_override_font_sizes/font_size = 10'
s.panel('Party','.',(178,244,272,105))
for i,(name,tex) in enumerate([('ティナ','terra_portrait'),('ロック','locke_portrait')]):
    p='Party/Member'+str(i+1);s.node('Member'+str(i+1),'Control','Party',rect((8,7+i*47,255,45))+'\nmouse_filter = 2');s.image('Portrait',p,'assets/art/'+tex+'.png',(0,0,34,40));s.label('Name',p,name,(43,0,198,15),11,GOLD);s.label('HP',p,'HP 120 / 120',(43,16,123,15),10);s.label('MP',p,'MP 30 / 30',(162,16,90,15),10,MUTED);s.bar('Health',p,(43,35,199,4))
s.panel('EnemyInfo','.',(461,244,167,75));s.label('Name','EnemyInfo','森のウルフ',(10,8,147,18),12,GOLD);s.bar('Health','EnemyInfo',(12,32,140,4));s.label('HP','EnemyInfo','56 / 56',(12,43,140,17),10,MUTED,2)
s.label('Help','.', '← → 敵を選ぶ / Z 決定',(463,327,166,15),9,MUTED)
s.color('Flash','.',(0,0,640,238),'Color(1,0.5,0.2,0)')
s.panel('Result','.',(124,77,392,194));s.nodes[-1]+='\nvisible = false';s.label('Title','Result','VICTORY',(14,16,364,34),27,GOLD,1);s.label('Subtitle','Result','魔物を倒した！',(18,64,356,27),15,CREAM,1);s.label('Rewards','Result','',(18,101,356,23),12,GOLD,1);s.button('Continue','Result','冒険へもどる',(105,147,182,30));s.save('scenes/ui/battle.tscn')

# Stubs are replaced by build_world.gd after the first texture import.
for name in ['town','forest']:
    path=ROOT/('scenes/world/'+name+'.tscn')
    if not path.exists():write('scenes/world/'+name+'.tscn','[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/world.gd" id="1"]\n[node name="World" type="Node2D"]\nscript = ExtResource("1")\n')

s=Scene();s.node('Starlight','Node2D',props='script = '+s.ext('scripts/game.gd','Script'));s.node('World',None,'.',instance=s.ext('scenes/world/town.tscn','PackedScene'));s.node('Party','Node2D','.', 'y_sort_enabled = true\nz_index = 3');s.node('Player',None,'Party','position = Vector2(405, 436)',s.ext('scenes/actors/player.tscn','PackedScene'));s.node('Companion',None,'Party','position = Vector2(424, 450)',s.ext('scenes/actors/companion.tscn','PackedScene'));s.node('UI','CanvasLayer','.')
for name in ['hud','title','menu','shop','dialogue','battle','ending']:
    s.node('HUD' if name=='hud' else name.title(),None,'UI',props='visible = false' if name not in ['hud','title'] else '',instance=s.ext('scenes/ui/'+name+'.tscn','PackedScene'))
s.node('Music','AudioStreamPlayer','.', 'volume_db = -9.0\nplayback_type = 0')
s.node('SFX','AudioStreamPlayer','.', 'volume_db = -5.0\nplayback_type = 0')
s.save('scenes/main.tscn')
# Individual UI scenes are visible when opened in the 2D editor. Initial hiding
# belongs to their instances in main.tscn, not to reusable component roots.
for name in ['menu','shop','dialogue','battle','ending']:
    p=ROOT/('scenes/ui/'+name+'.tscn')
    t=p.read_text(encoding='utf-8')
    root_start=t.index('[node ')
    root_end=t.index('\n[node ',root_start+1)
    root_text=t[root_start:root_end].replace('\nvisible = false','')
    p.write_text(t[:root_start]+root_text+t[root_end:],encoding='utf-8')
print('Authored scenes and resources.')
