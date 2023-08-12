# UB - UncensoredBulletin
It is not uncommon that legitimate Internet users have issues accessing legitimate (non-harmful, non-threatening)
resources due to their (users’) location. For example, users from certain parts of the World are not able to access
websites dedicated to harmless hobbies, which could be ridiculous, if it was not sad.

UncensoredBulletin v1.0.0 is rather a POC (Proof of Concept), a step towards a more sophisticated publishing
system, intended to help content creators reach their audiences. The system is intended to be virtually unblockable 
due to its server-less nature, the nature of the blockchain and IPFS technologies.

A side effect of this project is demonstration of NFT utilization for access/role control.

# Structure
The platform makes use of two smart contracts on Polygon chain (the plan is to extend it to Tron and Solana) – the
publishing smart contract (UB – UncensoredBulletin) and the access control (ETC – Editor Token Control) smart
contract which is, in fact, an ERC1155 NFT smart contract.

## UncensoredBulletin Smart Contract (deployed to [0xb7Be7465D0202E07f7D5d1F9281069497bFCaBd5](https://polygonscan.com/address/0xb7be7465d0202e07f7d5d1f9281069497bfcabd5))
The UB smart contract is used to publish textual items to blockchain and serve them to the general public or just
to subscribers based on the item type (this is discussed further in this document).

As it is not practical to store large texts on blockchain, the publisher may post a link to an external resource, which
contains the actual item. Since the idea behind UB is provision of global access, it is highly recommended to publish
longer texts to IPFS and put a link to them in the content of the post.

## ETC - The Editor Token Control Smart Contract (deployed to [0x36230bc334Bf202045C2AbDaE60D7028B407AF0E](https://polygonscan.com/address/0x36230bc334bf202045c2abdae60d7028b407af0e))
The ETC smart contract is a \[almost\] regular ERC1155 smart contract used for UB access administration. When
created, the one and only “Manager” token is minted (it is not possible to mint additional manager tokens).

## User Interface
As the intention is to make this platform usable for the general public, we are working on the graphical user interface.
The interface is using Electron as the underlying platform in order to provide serverless environment.
