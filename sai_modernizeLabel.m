function modern = sai_modernizeLabel(label)
%SAI_MODERNIZELABEL  Map outdated ImageNet class names to modern equivalents.
%   modern = sai_modernizeLabel(label) returns a friendlier version of the
%   ImageNet label if one exists, otherwise returns the input unchanged.

    persistent labelMap
    if isempty(labelMap)
        labelMap = containers.Map('KeyType','char','ValueType','char');

        % === Electronics & tech ===
        labelMap('cellular telephone') = 'Phone';
        labelMap('cellular phone') = 'Phone';
        labelMap('cell phone') = 'Phone';
        labelMap('iPod') = 'Music Player';
        labelMap('notebook') = 'Laptop';
        labelMap('notebook computer') = 'Laptop';
        labelMap('laptop') = 'Laptop';
        labelMap('desktop computer') = 'Computer';
        labelMap('screen') = 'Screen';
        labelMap('monitor') = 'Monitor';
        labelMap('television') = 'TV';
        labelMap('remote control') = 'Remote';
        labelMap('joystick') = 'Game Controller';
        labelMap('mouse') = 'Computer Mouse';
        labelMap('hand-held computer') = 'Tablet';
        labelMap('web site') = 'Website';
        labelMap('CRT screen') = 'Monitor';
        labelMap('computer keyboard') = 'Keyboard';
        labelMap('typewriter keyboard') = 'Typewriter';
        labelMap('hard disc') = 'Hard Drive';
        labelMap('modem') = 'Router';
        labelMap('cassette') = 'Cassette Tape';
        labelMap('cassette player') = 'Tape Player';
        labelMap('CD player') = 'CD Player';
        labelMap('tape player') = 'Tape Player';
        labelMap('dial telephone') = 'Old Phone';
        labelMap('pay-phone') = 'Pay Phone';
        labelMap('oscilloscope') = 'Science Equipment';
        labelMap('reflex camera') = 'Camera';
        labelMap('Polaroid camera') = 'Instant Camera';
        labelMap('photocopier') = 'Copier';
        labelMap('projector') = 'Projector';

        % === Clothing & accessories ===
        labelMap('running shoe') = 'Sneaker';
        labelMap('jean') = 'Jeans';
        labelMap('jersey') = 'Sports Jersey';
        labelMap('sweatshirt') = 'Hoodie';
        labelMap('sunglass') = 'Sunglasses';
        labelMap('maillot') = 'Swimsuit';
        labelMap('abaya') = 'Robe';
        labelMap('academic gown') = 'Graduation Gown';
        labelMap('mortarboard') = 'Graduation Cap';
        labelMap('vestment') = 'Robe';
        labelMap('stole') = 'Scarf';
        labelMap('feather boa') = 'Feather Scarf';
        labelMap('hoopskirt') = 'Big Dress';
        labelMap('overskirt') = 'Skirt';
        labelMap('miniskirt') = 'Skirt';
        labelMap('sarong') = 'Skirt';
        labelMap('gown') = 'Dress';
        labelMap('fur coat') = 'Coat';
        labelMap('trench coat') = 'Coat';
        labelMap('cloak') = 'Cape';
        labelMap('poncho') = 'Poncho';
        labelMap('bonnet') = 'Hat';
        labelMap('bearskin') = 'Fur Hat';
        labelMap('pickelhaube') = 'Spiked Helmet';
        labelMap('crash helmet') = 'Helmet';
        labelMap('hair slide') = 'Hair Clip';
        labelMap('Windsor tie') = 'Tie';
        labelMap('bolo tie') = 'Tie';
        labelMap('Loafer') = 'Shoe';
        labelMap('pajama') = 'Pajamas';
        labelMap('kimono') = 'Kimono';
        labelMap('bulletproof vest') = 'Vest';
        labelMap('chain mail') = 'Armor';
        labelMap('breastplate') = 'Armor';
        labelMap('cuirass') = 'Armor';

        % === Vehicles ===
        labelMap('cab') = 'Taxi';
        labelMap('minivan') = 'Van';
        labelMap('convertible') = 'Car';
        labelMap('limousine') = 'Limo';
        labelMap('recreational vehicle') = 'RV';
        labelMap('Model T') = 'Classic Car';
        labelMap('racer') = 'Race Car';
        labelMap('beach wagon') = 'Station Wagon';
        labelMap('pickup') = 'Pickup Truck';
        labelMap('trailer truck') = 'Semi Truck';
        labelMap('moving van') = 'Moving Truck';
        labelMap('garbage truck') = 'Garbage Truck';
        labelMap('tow truck') = 'Tow Truck';
        labelMap('go-kart') = 'Go-Kart';
        labelMap('golfcart') = 'Golf Cart';
        labelMap('motor scooter') = 'Scooter';
        labelMap('moped') = 'Scooter';
        labelMap('jinrikisha') = 'Rickshaw';
        labelMap('bicycle-built-for-two') = 'Tandem Bike';
        labelMap('bullet train') = 'Train';
        labelMap('electric locomotive') = 'Train';
        labelMap('steam locomotive') = 'Train';
        labelMap('freight car') = 'Train Car';
        labelMap('passenger car') = 'Train Car';
        labelMap('streetcar') = 'Trolley';
        labelMap('trolleybus') = 'Bus';
        labelMap('minibus') = 'Bus';
        labelMap('container ship') = 'Ship';
        labelMap('liner') = 'Cruise Ship';
        labelMap('catamaran') = 'Boat';
        labelMap('trimaran') = 'Boat';
        labelMap('gondola') = 'Boat';
        labelMap('schooner') = 'Sailboat';
        labelMap('yawl') = 'Sailboat';
        labelMap('airliner') = 'Airplane';
        labelMap('airship') = 'Blimp';
        labelMap('aircraft carrier') = 'Aircraft Carrier';
        labelMap('half track') = 'Military Vehicle';
        labelMap('warplane') = 'Fighter Jet';

        % === Dogs (well-known breeds — simplify) ===
        labelMap('golden retriever') = 'Golden Retriever';
        labelMap('Labrador retriever') = 'Labrador';
        labelMap('German shepherd') = 'German Shepherd';
        labelMap('French bulldog') = 'Bulldog';
        labelMap('Siberian husky') = 'Husky';
        labelMap('Yorkshire terrier') = 'Yorkie';
        labelMap('Pembroke') = 'Corgi';
        labelMap('Cardigan') = 'Corgi';
        labelMap('toy poodle') = 'Poodle';
        labelMap('miniature poodle') = 'Poodle';
        labelMap('standard poodle') = 'Poodle';
        labelMap('Boston bull') = 'Boston Terrier';
        labelMap('Old English sheepdog') = 'Sheepdog';
        labelMap('Shetland sheepdog') = 'Sheepdog';
        labelMap('Border collie') = 'Collie';

        % === Dogs (obscure breeds → "Dog") ===
        labelMap('Japanese spaniel') = 'Dog';
        labelMap('Maltese dog') = 'Dog';
        labelMap('Pekinese') = 'Dog';
        labelMap('Shih-Tzu') = 'Dog';
        labelMap('Blenheim spaniel') = 'Dog';
        labelMap('papillon') = 'Dog';
        labelMap('toy terrier') = 'Dog';
        labelMap('Rhodesian ridgeback') = 'Dog';
        labelMap('Afghan hound') = 'Dog';
        labelMap('basset') = 'Dog';
        labelMap('bloodhound') = 'Dog';
        labelMap('bluetick') = 'Dog';
        labelMap('black-and-tan coonhound') = 'Dog';
        labelMap('Walker hound') = 'Dog';
        labelMap('English foxhound') = 'Dog';
        labelMap('redbone') = 'Dog';
        labelMap('borzoi') = 'Dog';
        labelMap('Irish wolfhound') = 'Dog';
        labelMap('Italian greyhound') = 'Dog';
        labelMap('whippet') = 'Dog';
        labelMap('Ibizan hound') = 'Dog';
        labelMap('Norwegian elkhound') = 'Dog';
        labelMap('otterhound') = 'Dog';
        labelMap('Saluki') = 'Dog';
        labelMap('Scottish deerhound') = 'Dog';
        labelMap('Weimaraner') = 'Dog';
        labelMap('Staffordshire bullterrier') = 'Dog';
        labelMap('American Staffordshire terrier') = 'Dog';
        labelMap('Bedlington terrier') = 'Dog';
        labelMap('Border terrier') = 'Dog';
        labelMap('Kerry blue terrier') = 'Dog';
        labelMap('Irish terrier') = 'Dog';
        labelMap('Norfolk terrier') = 'Dog';
        labelMap('Norwich terrier') = 'Dog';
        labelMap('wire-haired fox terrier') = 'Dog';
        labelMap('Lakeland terrier') = 'Dog';
        labelMap('Sealyham terrier') = 'Dog';
        labelMap('Airedale') = 'Dog';
        labelMap('cairn') = 'Dog';
        labelMap('Australian terrier') = 'Dog';
        labelMap('Dandie Dinmont') = 'Dog';
        labelMap('miniature schnauzer') = 'Dog';
        labelMap('giant schnauzer') = 'Dog';
        labelMap('standard schnauzer') = 'Dog';
        labelMap('Scotch terrier') = 'Dog';
        labelMap('Tibetan terrier') = 'Dog';
        labelMap('silky terrier') = 'Dog';
        labelMap('soft-coated wheaten terrier') = 'Dog';
        labelMap('West Highland white terrier') = 'Dog';
        labelMap('Lhasa') = 'Dog';
        labelMap('flat-coated retriever') = 'Dog';
        labelMap('curly-coated retriever') = 'Dog';
        labelMap('Chesapeake Bay retriever') = 'Dog';
        labelMap('German short-haired pointer') = 'Dog';
        labelMap('vizsla') = 'Dog';
        labelMap('English setter') = 'Dog';
        labelMap('Irish setter') = 'Dog';
        labelMap('Gordon setter') = 'Dog';
        labelMap('Brittany spaniel') = 'Dog';
        labelMap('clumber') = 'Dog';
        labelMap('English springer') = 'Dog';
        labelMap('Welsh springer spaniel') = 'Dog';
        labelMap('Sussex spaniel') = 'Dog';
        labelMap('Irish water spaniel') = 'Dog';
        labelMap('kuvasz') = 'Dog';
        labelMap('schipperke') = 'Dog';
        labelMap('groenendael') = 'Dog';
        labelMap('malinois') = 'Dog';
        labelMap('briard') = 'Dog';
        labelMap('kelpie') = 'Dog';
        labelMap('komondor') = 'Dog';
        labelMap('Bouvier des Flandres') = 'Dog';
        labelMap('Doberman') = 'Dog';
        labelMap('miniature pinscher') = 'Dog';
        labelMap('Greater Swiss Mountain dog') = 'Dog';
        labelMap('Bernese mountain dog') = 'Dog';
        labelMap('Appenzeller') = 'Dog';
        labelMap('EntleBucher') = 'Dog';
        labelMap('bull mastiff') = 'Dog';
        labelMap('Tibetan mastiff') = 'Dog';
        labelMap('Saint Bernard') = 'Dog';
        labelMap('Eskimo dog') = 'Dog';
        labelMap('malamute') = 'Dog';
        labelMap('affenpinscher') = 'Dog';
        labelMap('basenji') = 'Dog';
        labelMap('Leonberg') = 'Dog';
        labelMap('Newfoundland') = 'Dog';
        labelMap('Great Pyrenees') = 'Dog';
        labelMap('Samoyed') = 'Dog';
        labelMap('Pomeranian') = 'Dog';
        labelMap('chow') = 'Dog';
        labelMap('keeshond') = 'Dog';
        labelMap('Brabancon griffon') = 'Dog';
        labelMap('Mexican hairless') = 'Dog';

        % === Cats ===
        labelMap('tabby') = 'Cat';
        labelMap('tabby cat') = 'Cat';
        labelMap('Egyptian cat') = 'Cat';
        labelMap('Persian cat') = 'Cat';
        labelMap('Siamese cat') = 'Cat';
        labelMap('tiger cat') = 'Cat';

        % === Wild cats ===
        labelMap('cougar') = 'Mountain Lion';
        labelMap('snow leopard') = 'Snow Leopard';

        % === Wild canines ===
        labelMap('timber wolf') = 'Wolf';
        labelMap('white wolf') = 'Wolf';
        labelMap('red wolf') = 'Wolf';
        labelMap('red fox') = 'Fox';
        labelMap('kit fox') = 'Fox';
        labelMap('Arctic fox') = 'Arctic Fox';
        labelMap('grey fox') = 'Fox';
        labelMap('dhole') = 'Wild Dog';
        labelMap('African hunting dog') = 'Wild Dog';

        % === Bears ===
        labelMap('ice bear') = 'Polar Bear';
        labelMap('American black bear') = 'Black Bear';
        labelMap('brown bear') = 'Bear';
        labelMap('sloth bear') = 'Bear';

        % === Primates ===
        labelMap('guenon') = 'Monkey';
        labelMap('patas') = 'Monkey';
        labelMap('macaque') = 'Monkey';
        labelMap('langur') = 'Monkey';
        labelMap('colobus') = 'Monkey';
        labelMap('proboscis monkey') = 'Monkey';
        labelMap('marmoset') = 'Monkey';
        labelMap('capuchin') = 'Monkey';
        labelMap('howler monkey') = 'Monkey';
        labelMap('titi') = 'Monkey';
        labelMap('spider monkey') = 'Monkey';
        labelMap('squirrel monkey') = 'Monkey';
        labelMap('siamang') = 'Monkey';
        labelMap('gibbon') = 'Monkey';
        labelMap('Madagascar cat') = 'Lemur';
        labelMap('indri') = 'Lemur';

        % === Other mammals ===
        labelMap('tusker') = 'Elephant';
        labelMap('Indian elephant') = 'Elephant';
        labelMap('African elephant') = 'Elephant';
        labelMap('lesser panda') = 'Red Panda';
        labelMap('giant panda') = 'Panda';
        labelMap('three-toed sloth') = 'Sloth';
        labelMap('Arabian camel') = 'Camel';
        labelMap('wallaby') = 'Wallaby';
        labelMap('sorrel') = 'Horse';
        labelMap('hog') = 'Pig';
        labelMap('wild boar') = 'Wild Pig';
        labelMap('water buffalo') = 'Buffalo';
        labelMap('bighorn') = 'Sheep';
        labelMap('ibex') = 'Mountain Goat';
        labelMap('hartebeest') = 'Antelope';
        labelMap('impala') = 'Antelope';
        labelMap('black-footed ferret') = 'Ferret';
        labelMap('mink') = 'Weasel';
        labelMap('polecat') = 'Weasel';
        labelMap('wood rabbit') = 'Rabbit';
        labelMap('hare') = 'Rabbit';
        labelMap('Angora') = 'Rabbit';
        labelMap('fox squirrel') = 'Squirrel';
        labelMap('marmot') = 'Groundhog';
        labelMap('guinea pig') = 'Guinea Pig';

        % === Marine mammals ===
        labelMap('grey whale') = 'Whale';
        labelMap('killer whale') = 'Orca';
        labelMap('dugong') = 'Manatee';

        % === Fish ===
        labelMap('tench') = 'Fish';
        labelMap('coho') = 'Fish';
        labelMap('rock beauty') = 'Fish';
        labelMap('anemone fish') = 'Clownfish';
        labelMap('sturgeon') = 'Fish';
        labelMap('gar') = 'Fish';
        labelMap('puffer') = 'Pufferfish';
        labelMap('barracouta') = 'Fish';
        labelMap('great white shark') = 'Shark';
        labelMap('tiger shark') = 'Shark';
        labelMap('hammerhead') = 'Shark';
        labelMap('electric ray') = 'Ray';

        % === Birds (simplify) ===
        labelMap('cock') = 'Rooster';
        labelMap('hen') = 'Chicken';
        labelMap('bald eagle') = 'Eagle';
        labelMap('great grey owl') = 'Owl';
        labelMap('African grey') = 'Parrot';
        labelMap('macaw') = 'Parrot';
        labelMap('sulphur-crested cockatoo') = 'Cockatoo';
        labelMap('lorikeet') = 'Parrot';
        labelMap('drake') = 'Duck';
        labelMap('red-breasted merganser') = 'Duck';
        labelMap('black swan') = 'Swan';
        labelMap('king penguin') = 'Penguin';
        labelMap('white stork') = 'Stork';
        labelMap('black stork') = 'Stork';
        labelMap('American egret') = 'Heron';
        labelMap('little blue heron') = 'Heron';
        labelMap('European gallinule') = 'Bird';
        labelMap('American coot') = 'Bird';
        labelMap('prairie chicken') = 'Bird';
        labelMap('black grouse') = 'Bird';
        labelMap('ruffed grouse') = 'Bird';
        labelMap('ptarmigan') = 'Bird';
        labelMap('brambling') = 'Bird';
        labelMap('goldfinch') = 'Bird';
        labelMap('house finch') = 'Bird';
        labelMap('junco') = 'Bird';
        labelMap('indigo bunting') = 'Bird';
        labelMap('bulbul') = 'Bird';
        labelMap('chickadee') = 'Bird';
        labelMap('water ouzel') = 'Bird';
        labelMap('coucal') = 'Bird';
        labelMap('bee eater') = 'Bird';
        labelMap('jacamar') = 'Bird';
        labelMap('limpkin') = 'Bird';
        labelMap('bustard') = 'Bird';
        labelMap('ruddy turnstone') = 'Bird';
        labelMap('red-backed sandpiper') = 'Bird';
        labelMap('redshank') = 'Bird';
        labelMap('dowitcher') = 'Bird';
        labelMap('oystercatcher') = 'Bird';

        % === Reptiles ===
        labelMap('common iguana') = 'Iguana';
        labelMap('American chameleon') = 'Chameleon';
        labelMap('African chameleon') = 'Chameleon';
        labelMap('banded gecko') = 'Gecko';
        labelMap('whiptail') = 'Lizard';
        labelMap('agama') = 'Lizard';
        labelMap('frilled lizard') = 'Lizard';
        labelMap('alligator lizard') = 'Lizard';
        labelMap('green lizard') = 'Lizard';
        labelMap('African crocodile') = 'Crocodile';
        labelMap('American alligator') = 'Alligator';
        labelMap('loggerhead') = 'Sea Turtle';
        labelMap('leatherback turtle') = 'Sea Turtle';
        labelMap('mud turtle') = 'Turtle';
        labelMap('terrapin') = 'Turtle';
        labelMap('box turtle') = 'Turtle';

        % === Amphibians ===
        labelMap('European fire salamander') = 'Salamander';
        labelMap('common newt') = 'Newt';
        labelMap('eft') = 'Newt';
        labelMap('spotted salamander') = 'Salamander';
        labelMap('bullfrog') = 'Frog';
        labelMap('tailed frog') = 'Frog';

        % === Snakes (all → "Snake") ===
        labelMap('thunder snake') = 'Snake';
        labelMap('ringneck snake') = 'Snake';
        labelMap('hognose snake') = 'Snake';
        labelMap('green snake') = 'Snake';
        labelMap('king snake') = 'Snake';
        labelMap('garter snake') = 'Snake';
        labelMap('water snake') = 'Snake';
        labelMap('vine snake') = 'Snake';
        labelMap('night snake') = 'Snake';
        labelMap('boa constrictor') = 'Snake';
        labelMap('rock python') = 'Snake';
        labelMap('Indian cobra') = 'Snake';
        labelMap('green mamba') = 'Snake';
        labelMap('sea snake') = 'Snake';
        labelMap('horned viper') = 'Snake';
        labelMap('diamondback') = 'Snake';
        labelMap('sidewinder') = 'Snake';

        % === Spiders ===
        labelMap('black and gold garden spider') = 'Spider';
        labelMap('barn spider') = 'Spider';
        labelMap('garden spider') = 'Spider';
        labelMap('black widow') = 'Spider';
        labelMap('wolf spider') = 'Spider';

        % === Insects ===
        labelMap('tiger beetle') = 'Beetle';
        labelMap('ground beetle') = 'Beetle';
        labelMap('long-horned beetle') = 'Beetle';
        labelMap('leaf beetle') = 'Beetle';
        labelMap('dung beetle') = 'Beetle';
        labelMap('rhinoceros beetle') = 'Beetle';
        labelMap('weevil') = 'Bug';
        labelMap('harvestman') = 'Bug';
        labelMap('isopod') = 'Bug';
        labelMap('leafhopper') = 'Bug';
        labelMap('lacewing') = 'Bug';
        labelMap('walking stick') = 'Stick Bug';
        labelMap('mantis') = 'Praying Mantis';
        labelMap('damselfly') = 'Dragonfly';
        labelMap('admiral') = 'Butterfly';
        labelMap('ringlet') = 'Butterfly';
        labelMap('monarch') = 'Butterfly';
        labelMap('cabbage butterfly') = 'Butterfly';
        labelMap('sulphur butterfly') = 'Butterfly';
        labelMap('lycaenid') = 'Butterfly';

        % === Crustaceans & mollusks ===
        labelMap('Dungeness crab') = 'Crab';
        labelMap('rock crab') = 'Crab';
        labelMap('fiddler crab') = 'Crab';
        labelMap('king crab') = 'Crab';
        labelMap('American lobster') = 'Lobster';
        labelMap('spiny lobster') = 'Lobster';
        labelMap('conch') = 'Seashell';
        labelMap('chambered nautilus') = 'Nautilus';
        labelMap('brain coral') = 'Coral';

        % === Food & drink ===
        labelMap('espresso') = 'Coffee';
        labelMap('cup') = 'Cup';
        labelMap('coffee mug') = 'Mug';
        labelMap('pop bottle') = 'Soda Bottle';
        labelMap('water bottle') = 'Water Bottle';
        labelMap('wine bottle') = 'Wine Bottle';
        labelMap('beer bottle') = 'Beer Bottle';
        labelMap('beer glass') = 'Beer Glass';
        labelMap('French loaf') = 'Bread';
        labelMap('mashed potato') = 'Mashed Potatoes';
        labelMap('head cabbage') = 'Cabbage';
        labelMap('spaghetti squash') = 'Squash';
        labelMap('acorn squash') = 'Squash';
        labelMap('butternut squash') = 'Squash';
        labelMap('bell pepper') = 'Pepper';
        labelMap('cardoon') = 'Artichoke';
        labelMap('Granny Smith') = 'Apple';
        labelMap('custard apple') = 'Fruit';
        labelMap('carbonara') = 'Pasta';
        labelMap('meat loaf') = 'Meatloaf';
        labelMap('potpie') = 'Pot Pie';
        labelMap('red wine') = 'Wine';
        labelMap('consomme') = 'Soup';
        labelMap('hot pot') = 'Soup';
        labelMap('trifle') = 'Dessert';
        labelMap('ice lolly') = 'Popsicle';

        % === Household ===
        labelMap('washbasin') = 'Sink';
        labelMap('wash basin') = 'Sink';
        labelMap('bathtub') = 'Bathtub';
        labelMap('toilet tissue') = 'Toilet Paper';
        labelMap('toilet seat') = 'Toilet';
        labelMap('electric fan') = 'Fan';
        labelMap('table lamp') = 'Lamp';
        labelMap('lampshade') = 'Lamp';
        labelMap('desk') = 'Desk';
        labelMap('dining table') = 'Table';
        labelMap('rocking chair') = 'Chair';
        labelMap('folding chair') = 'Chair';
        labelMap('studio couch') = 'Couch';
        labelMap('four-poster') = 'Bed';
        labelMap('cradle') = 'Baby Crib';
        labelMap('crib') = 'Baby Crib';
        labelMap('bassinet') = 'Baby Bed';
        labelMap('chiffonier') = 'Dresser';
        labelMap('china cabinet') = 'Cabinet';
        labelMap('wardrobe') = 'Closet';
        labelMap('refrigerator') = 'Fridge';
        labelMap('Crock Pot') = 'Slow Cooker';
        labelMap('Dutch oven') = 'Pot';
        labelMap('coffeepot') = 'Coffee Pot';
        labelMap('espresso maker') = 'Coffee Machine';
        labelMap('caldron') = 'Cauldron';
        labelMap('ashcan') = 'Trash Can';
        labelMap('hamper') = 'Laundry Basket';
        labelMap('hand blower') = 'Hair Dryer';
        labelMap('doormat') = 'Welcome Mat';
        labelMap('shower curtain') = 'Shower Curtain';
        labelMap('window shade') = 'Window Blind';
        labelMap('entertainment center') = 'TV Stand';
        labelMap('home theater') = 'Home Theater';
        labelMap('tub') = 'Bathtub';
        labelMap('washer') = 'Washing Machine';
        labelMap('dishrag') = 'Dish Towel';

        % === Office & school ===
        labelMap('ballpoint') = 'Pen';
        labelMap('ballpoint pen') = 'Pen';
        labelMap('fountain pen') = 'Pen';
        labelMap('pencil box') = 'Pencil Case';
        labelMap('binder') = 'Binder';
        labelMap('rubber eraser') = 'Eraser';
        labelMap('rule') = 'Ruler';
        labelMap('ruler') = 'Ruler';
        labelMap('slide rule') = 'Calculator';

        % === Buildings & places ===
        labelMap('cinema') = 'Movie Theater';
        labelMap('confectionery') = 'Candy Shop';
        labelMap('grocery store') = 'Grocery Store';
        labelMap('tobacco shop') = 'Shop';
        labelMap('cliff dwelling') = 'Cliff House';
        labelMap('stupa') = 'Temple';
        labelMap('monastery') = 'Monastery';
        labelMap('bell cote') = 'Bell Tower';
        labelMap('drilling platform') = 'Oil Rig';
        labelMap('lumbermill') = 'Sawmill';
        labelMap('steel arch bridge') = 'Bridge';
        labelMap('suspension bridge') = 'Bridge';
        labelMap('viaduct') = 'Bridge';
        labelMap('megalith') = 'Stone Monument';
        labelMap('obelisk') = 'Monument';
        labelMap('triumphal arch') = 'Arch';

        % === Nature & scenery ===
        labelMap('alp') = 'Mountain';
        labelMap('promontory') = 'Cliff';
        labelMap('sandbar') = 'Beach';
        labelMap('seashore') = 'Beach';
        labelMap('rapeseed') = 'Flower Field';
        labelMap('yellow lady''s slipper') = 'Orchid';

        % === Tools & equipment ===
        labelMap('carpenter''s kit') = 'Toolbox';
        labelMap('hatchet') = 'Axe';
        labelMap('chain saw') = 'Chainsaw';
        labelMap('harvester') = 'Tractor';
        labelMap('loudspeaker') = 'Speaker';
        labelMap('loupe') = 'Magnifying Glass';
        labelMap('magnetic compass') = 'Compass';
        labelMap('radio telescope') = 'Telescope';
        labelMap('face powder') = 'Makeup';
        labelMap('solar dish') = 'Satellite Dish';
        labelMap('cash machine') = 'ATM';
        labelMap('carousel') = 'Merry-Go-Round';
        labelMap('slot') = 'Slot Machine';
        labelMap('marimba') = 'Xylophone';
        labelMap('cornet') = 'Trumpet';
        labelMap('panpipe') = 'Flute';
        labelMap('sax') = 'Saxophone';
        labelMap('upright') = 'Piano';
        labelMap('grand piano') = 'Piano';

        % === Misc objects ===
        labelMap('gasmask') = 'Gas Mask';
        labelMap('plate') = 'Plate';
        labelMap('mixing bowl') = 'Bowl';
        labelMap('soup bowl') = 'Bowl';
        labelMap('carton') = 'Box';
        labelMap('crate') = 'Box';
        labelMap('car mirror') = 'Mirror';
        labelMap('car wheel') = 'Wheel';
        labelMap('jack-o''-lantern') = 'Jack-o-Lantern';
        labelMap('missile') = 'Rocket';
        labelMap('projectile') = 'Rocket';
        labelMap('picket fence') = 'Fence';
        labelMap('chainlink fence') = 'Fence';
        labelMap('worm fence') = 'Fence';
        labelMap('shoji') = 'Sliding Door';
        labelMap('puck') = 'Hockey Puck';
        labelMap('racket') = 'Tennis Racket';
        labelMap('saltshaker') = 'Salt Shaker';
        labelMap('thatch') = 'Thatched Roof';
        labelMap('bannister') = 'Railing';
        labelMap('barrow') = 'Wheelbarrow';
        labelMap('oxcart') = 'Cart';
        labelMap('horse cart') = 'Horse Cart';
        labelMap('dogsled') = 'Dog Sled';
        labelMap('purse') = 'Purse';
        labelMap('matchstick') = 'Match';
        labelMap('combination lock') = 'Lock';
        labelMap('padlock') = 'Lock';
        labelMap('spider web') = 'Spiderweb';
        labelMap('space bar') = 'Keyboard';

        % Normalize all keys to lowercase for case-insensitive lookup
        allKeys = labelMap.keys;
        allVals = labelMap.values;
        labelMap = containers.Map(lower(allKeys), allVals);
    end

    name = char(label);
    % Try exact match first (case-insensitive)
    lowerName = lower(strtrim(name));
    if labelMap.isKey(lowerName)
        modern = labelMap(lowerName);
    else
        modern = name;
    end
end
