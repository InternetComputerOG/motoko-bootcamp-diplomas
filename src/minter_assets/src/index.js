import { Actor, HttpAgent } from "@dfinity/agent"
import { idlFactory, IDL } from "../../declarations/minter";

const canister_id = "pgsou-iyaaa-aaaal-aaifq-cai";
const update_button = document.getElementById("update");
const plug_button = document.getElementById("plug");
const set_template_button = document.getElementById("setTemplate");
const host = "https://mainnet.dfinity.network";
const whitelist = [canister_id];
const admin = "gj3h2-k3kw2-ciszt-6zylp-azl7o-mvg5j-eudtf-fpejf-mx2rd-ifsul-dqe";
const admin_forms = document.getElementById("admin");
const graduate_form = document.getElementById("graduate");
const update_graduate_button = document.getElementById("update-graduate");
var actor_diploma = null;
var principalId = null;
var graduate = null;

const plugConnection = async () => {
  plug_button.innerText = "Please wait...";

  const result = await (window).ic.plug.requestConnect({
    whitelist,
    host,
  });
  if (!result) {
    plug_button.innerText = "Connect Plug Wallet";
    return;
  }
  
  principalId = await window.ic.plug.agent.getPrincipal();

  actor_diploma = await window.ic.plug.createActor({
    canisterId: canister_id,
    interfaceFactory: idlFactory,
  });

  console.log("about to get diploma")
  graduate = await actor_diploma.get_diploma(principalId);
  console.log("got diploma")

  plug_button.classList.add("hide-this");

  // if (graduate.length == 1) {
  //   document.getElementById("greeting").innerText = graduate[0];
  //   //return;
  //   graduate = ["7","Bob", "aiv55", "1", "Beginner Track", "3.12.22", "looking-status"];
  // };

  graduate = ["7","Isaac Valadez", "aiv55", "1", "Intermediate Track", "3.12.22", "looking-status"];

  graduate_form.classList.remove("hide-this");

  document.getElementById("greeting").innerText = "Welcome back, " + graduate[1] + "!";

  const tokenId = graduate[0];
  document.getElementById("nft").src = "https://pgsou-iyaaa-aaaal-aaifq-cai.raw.ic0.app/?tokenid=" + tokenId;

  document.getElementById("full-name-label").innerText = "Name: " + graduate[1];
  //document.getElementById("full-name").value = graduate[1];
  document.getElementById("DSCVR-label").innerText = "DSCVR Username: " + graduate[2];
  //document.getElementById("DSCVR").value = graduate[2];
  console.log("Testing");
  console.log(graduate);
  if (graduate[3] == "1") {
    document.getElementById("full-name").checked = true;
  } else if (graduate[3] == "2") {
    document.getElementById("DSCVR").checked = true;
  } else {
    document.getElementById("private").checked = true;
  };
  console.log("Testing 2");
  console.log(graduate);
  if (graduate[6] == "looking-status") {
    document.getElementById("looking").checked = true;
  } else if (graduate[6] == "hiring-status") {
    document.getElementById("hiring").checked = true;
  } else {
    document.getElementById("neutral").checked = true;
  };
  console.log("Testing 3");
  console.log(graduate);

  // if (principalId == admin) {
  //   admin_forms.classList.remove("hide-this");
  //   set_template_button.addEventListener("click", set_template);
  //   update_graduate_button.addEventListener("click", admin_edit_graduate);
  // }
};
console.log("Testing 4");
console.log(graduate);

plug_button.addEventListener("click", plugConnection);

update_button.addEventListener("click", async function(e) {
    e.preventDefault();
    document.getElementById("greeting").innerText = "Updating Diploma...";

    graduate[3] = document.querySelector('input[name="preferred-name"]:checked').value;
    graduate[6] = document.querySelector('input[name="set-status"]:checked').value;
    console.log("Testing 5");
    console.log(graduate);
    console.log("update button pressed");

    document.getElementById("greeting").innerText = await actor_diploma.update_uri(graduate);
    console.log(graduate);

    // Create a timestamp
    var img_src = "https://pgsou-iyaaa-aaaal-aaifq-cai.raw.ic0.app/?tokenid=" + graduate[0];
    console.log(img_src);
    const reloadImg = url =>
      fetch(url, { cache: 'reload', mode: 'no-cors' })
      .then(() => document.body.querySelectorAll(`img[src='${url}']`)
      .forEach(img => img.src = url))

    var reload = await reloadImg(img_src);

    // update_button.addEventListener("click", update_nft(graduate));
});




// const admin_edit_graduate = async () => {
//   const edit_graduate_0 = document.getElementById("edit-graduate-0").value.toString();
//   const edit_graduate_1 = document.getElementById("edit-graduate-1").value.toString();
//   const edit_graduate_2 = document.getElementById("edit-graduate-2").value.toString();
//   const edit_graduate_3 = document.getElementById("edit-graduate-3").value.toString();
//   const edit_graduate_4 = document.getElementById("edit-graduate-4").value.toString();
//   const edit_graduate_5 = document.getElementById("edit-graduate-5").value.toString();
//   const edit_graduate_6 = document.getElementById("edit-graduate-6").value.toString();

//   var send_update = await actor_diploma.update_uri([edit_graduate_0, edit_graduate_1, edit_graduate_2, edit_graduate_3, edit_graduate_4, edit_graduate_5, edit_graduate_6]);
//   console.log("Graduate set (probably)");
// }