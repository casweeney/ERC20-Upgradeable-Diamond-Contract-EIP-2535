/* global ethers */
/* eslint prefer-const: "off" */

const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

async function deployDiamond () {
  

  // deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
  // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
  const diamondInit = await ethers.getContractAt('DiamondInit', '0xC0Efc158722B88F80c3Cc0b47aF86F67f9786B67')
  

  // deploy facets
  console.log('')
  console.log('Deploying facets')
  const FacetNames = ['ERC20WithdrawFacet']
  const cut = []

  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName)
    const facet = await Facet.deploy()
    await facet.deployed()
    console.log(`${FacetName} deployed: ${facet.address}`)
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet)
    })
  }

  // upgrade diamond with facets
  console.log('')
  console.log('Diamond Cut:', cut)

  const diamondCut = await ethers.getContractAt('IDiamondCut', '0xc3c7B1fCe0C5D9E6D8321f3491536995868b7b3b')
  let tx
  let receipt

  // call to init function
  let functionCall = diamondInit.interface.encodeFunctionData('init')
  tx = await diamondCut.diamondCut(cut, '0xC0Efc158722B88F80c3Cc0b47aF86F67f9786B67', functionCall)
  console.log('Diamond cut tx: ', tx.hash)

  receipt = await tx.wait()

  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }
  console.log('Completed diamond cut')
  // return diamond.address


  const token = await ethers.getContractAt("ERC20Facet", '0xc3c7B1fCe0C5D9E6D8321f3491536995868b7b3b');
  const name = await token.name();

  // await token.mint(contractOwner.address, 10000);

  const balance = await token.balanceOf(contractOwner.address);

  console.log(name);
  console.log(Number(balance));

  /// Diamond contract deployed on goerli at: 0x9986DA37bC394F2290a7186A6CF47626B5bF10dd
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployDiamond = deployDiamond
