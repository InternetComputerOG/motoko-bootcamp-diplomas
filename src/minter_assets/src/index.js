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
const transfer_nft_button = document.getElementById("transfer-nft");
const mint_diploma_button = document.getElementById("mint-diploma-btn");
var actor_diploma = null;
var principalId = null;
var graduate_token_id = null;
var graduate = null;

const plugConnection = async () => {
  document.getElementById("greeting").innerText = "Waiting on permission from Plug";
  plug_button.disabled = true;
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

  document.getElementById("greeting").innerText = "Loading your information...";
  console.log("about to get diploma")
  graduate = await actor_diploma.get_diploma(principalId);
  graduate = graduate[0];
  console.log("got diploma")

  if (graduate == null) {
    document.getElementById("greeting").innerText = "Sorry, it looks like you don't have a diploma!";
    plug_button.classList.add("hide-this");
    return;
  };

  var tokenId = await actor_diploma.get_token_by_principal(principalId);
  graduate_token_id = Number(tokenId);
  document.getElementById("nft").src = "https://pgsou-iyaaa-aaaal-aaifq-cai.raw.ic0.app/?tokenid=" + graduate_token_id;
  document.getElementById("nft-anchor").href = "https://pgsou-iyaaa-aaaal-aaifq-cai.raw.ic0.app/?tokenid=" + graduate_token_id;

  document.getElementById("full-name-label").innerText = "Name: " + graduate.name;
  document.getElementById("DSCVR-label").innerText = "DSCVR Username: " + graduate.username;

  if (graduate.preference == "1") {
    document.getElementById("full-name").checked = true;
  } else if (graduate.preference == "2") {
    document.getElementById("DSCVR").checked = true;
  } else {
    document.getElementById("private").checked = true;
  };

  if (graduate.status == "looking-status") {
    document.getElementById("looking").checked = true;
  } else if (graduate.status == "hiring-status") {
    document.getElementById("hiring").checked = true;
  } else {
    document.getElementById("neutral").checked = true;
  };

  document.getElementById("greeting").innerText = "Welcome back, " + graduate.name + "!";
  plug_button.classList.add("hide-this");
  graduate_form.classList.remove("hide-this");

  if (principalId == admin) {
    admin_forms.classList.remove("hide-this");
    set_template_button.addEventListener("click", set_template);
    update_graduate_button.addEventListener("click", admin_edit_graduate);
    transfer_nft_button.addEventListener("click", admin_transfer_nft);
    mint_diploma_button.addEventListener("click", admin_mint_diploma);
  };
};

plug_button.addEventListener("click", plugConnection);

update_button.addEventListener("click", async function(e) {
    e.preventDefault();
    update_button.disabled = true;
    update_button.innerText = "loading...";
    document.getElementById("greeting").innerText = "Updating Diploma...";

    var preference = Number(document.querySelector('input[name="preferred-name"]:checked').value);
    var status = document.querySelector('input[name="set-status"]:checked').value;
    console.log("update button pressed");

    var new_greeting = await actor_diploma.update_uri(graduate_token_id, status, preference);
    console.log(graduate);

    // Create a timestamp
    var img_src = "https://pgsou-iyaaa-aaaal-aaifq-cai.raw.ic0.app/?tokenid=" + graduate_token_id;

    console.log(img_src);

    const reloadImg = url =>
      fetch(url, { cache: 'reload', mode: 'no-cors' })
      .then(() => document.body.querySelectorAll(`img[src='${url}']`)
      .forEach(img => img.src = url))

    var reload = await reloadImg(img_src);

    document.getElementById("greeting").innerText = new_greeting;
    update_button.disabled = false;
    update_button.innerText = "Update Diploma!";
});

const admin_transfer_nft = async () => {
  var tokenId = Number(document.getElementById("transfer-token").value);
  const from_prin = document.getElementById("transfer-from").value;
  const to_prin = document.getElementById("transfer-to").value;

  var send_update = await actor_diploma.transferFrom(from_prin, to_prin, tokenId);
  console.log("Token transferred (probably)");
}

const set_template = async () => {
  const svg_template = document.getElementById("svg-template").value;

  var send_update = await actor_diploma.set_svg_template(svg_template);
  console.log("SVG Template set (probably)");
}

const admin_edit_graduate = async () => {
  var tokenId = Number(document.getElementById("edit-graduate-0").value);

  var grad = {
    name: document.getElementById("edit-graduate-1").value,
    username: document.getElementById("edit-graduate-2").value,
    preference: Number(document.getElementById("edit-graduate-3").value),
    track: document.getElementById("edit-graduate-4").value,
    date: document.getElementById("edit-graduate-5").value.toString(),
    status: document.getElementById("edit-graduate-6").value,
    desc1: document.getElementById("edit-graduate-7").value,
    desc2: document.getElementById("edit-graduate-8").value
  }

  console.log(grad);

  var send_update = await actor_diploma.admin_update_graduate(tokenId, grad);
  console.log(send_update);
}

const admin_mint_diploma = async () => {
  var principal_to = document.getElementById("mint-diploma-0").value;

  var grad = {
    name: document.getElementById("mint-diploma-1").value,
    username: document.getElementById("mint-diploma-2").value,
    preference: Number(document.getElementById("mint-diploma-3").value),
    track: document.getElementById("mint-diploma-4").value,
    date: document.getElementById("mint-diploma-5").value.toString(),
    status: document.getElementById("mint-diploma-6").value,
    desc1: document.getElementById("mint-diploma-7").value,
    desc2: document.getElementById("mint-diploma-8").value
  }

  console.log(grad);

  var send_update = await actor_diploma.mint(principal_to, grad);
  console.log(send_update);
}