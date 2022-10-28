export function buildTokenURI(baseURI: string, address: string, tokenId: number) {
	return baseURI + address.toLowerCase() + '/' + tokenId;
}