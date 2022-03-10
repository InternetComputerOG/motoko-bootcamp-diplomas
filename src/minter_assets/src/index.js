// The minter is the representation of the minter contract in main.mo but in JavaScript
import { minter, canisterId, IDL } from "../../declarations/minter";


// For beginners : This is really basic Javascript code that add an event to the "Mint" button so that the mint_nft function is called when the button is clicked.
const mint_button = document.getElementById("mint");

const plug_button = document.getElementById("plug");
plug_button.addEventListener("click", login_to_plug);

document.getElementById("nft").src = "https://pgsou-iyaaa-aaaal-aaifq-cai.raw.ic0.app/?tokenid=4";

async function login_to_plug() {

  // Whitelist
  const whitelist = [canisterId];
  
  // Make the request
  const isConnected = await window.ic.plug.requestConnect({
    whitelist,
  });
  
  // Get the user principal id
  const principalId = await window.ic.plug.agent.getPrincipal();

  // Show some information about the minted image.
  document.getElementById("greeting").innerText = "Plug's user principal Id is " + principalId;

  const mint_nft = async () => {
    // Get the url of the image from the input field
    const name = document.getElementById("name").value.toString();
    console.log("The url we are trying to mint is " + name);
  
    // Mint the image by calling the mint_principal function of the minter.
    const mintId = await minter.mint(name);
    console.log("The id is " + Number(mintId));
  
    // Get the url by asking the minter contract.
    document.getElementById("nft").src = "https://pgsou-iyaaa-aaaal-aaifq-cai.raw.ic0.app/?tokenid=4";
  
    // Show some information about the minted image.
    document.getElementById("greeting").innerText = "this nft owner is " + principalId + "\nthis token id is " + Number(mintId);
  }

  mint_button.addEventListener("click", mint_nft);
  mint_button.disabled = false;
}