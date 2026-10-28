(() => {
"use strict";
const KEY="orion_pos_v2_data";
const seedProducts=[
["Mozzarella Coklat","Corndog",18000,8958,"🍫",30],
["Mozzarella Tiramisu","Corndog",18000,9454,"🍪",30],
["Mozzarella Greentea","Corndog",18000,9454,"🍵",30],
["Mozzarella Taro","Corndog",18000,9454,"🟣",30],
["Sosis Reguler","Corndog",8000,4205,"🌭",30],
["Sosis Premium","Corndog",12000,5697,"🌭",30],
["Mozzarella Sosis","Corndog",16000,6701,"🧀",30],
["Mozzarella Original","Corndog",18000,7705,"🧀",30],
["Sosis Kentang Reguler","Corndog Kentang",11000,6058,"🥔",25],
["Sosis Kentang Jumbo","Corndog Kentang",22000,8883,"🥔",25],
["Mozzarella Kentang","Corndog Kentang",21000,9555,"🥔",25],
["Dimsum Original Isi 6","Dimsum",25000,14250,"🥟",20],
["Dimsum Spicy Mayo Isi 6","Dimsum",28000,17910,"🥟",20],
["Kentang Goreng","Snack",10000,4470,"🍟",25],
["Sosis Jumbo Bakar","Sosis Bakar",10000,4808,"🌭",25],
["Dumpling Keju Bakar","Sosis Bakar",5000,3088,"🍢",30]
].map((x,i)=>({id:i+1,name:x[0],category:x[1],price:x[2],hpp:x[3],icon:x[4],stock:x[5],active:true,createdAt:new Date().toISOString()}));
function fresh(){return {products:seedProducts,categories:["Corndog","Corndog Kentang","Dimsum","Snack","Sosis Bakar","Minuman","Pisang","Lainnya"],promos:[],sales:[],finance:[],attendance:[],closings:[],settings:{outlet:"OR!ON CORNDOG",address:"",phone:"",footer:"Terima kasih telah membeli!",lowStock:5},users:[{name:"Admin Outlet",email:"admin@orion.local",role:"admin"}]};}
function load(){try{const d=JSON.parse(localStorage.getItem(KEY));if(d&&Array.isArray(d.products))return {...fresh(),...d};}catch(e){}return fresh();}
function save(data){localStorage.setItem(KEY,JSON.stringify(data));}
window.ORION_DB={KEY,fresh,load,save,seedProducts};
})();